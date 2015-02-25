//
//  FPConnection.m
//  PostgreSQL.framework
//
//  Created by Flying Pig on 8/2/06.
//  Copyright © 2008 Flying Pig. All rights reserved.
//
//  Redistribution and use in binary form, without modification, are permitted provided that the following conditions are met:
//  ¥	Redistributions in binary form must not be under any other license or conditions other than the ones described in this notice.
//  ¥	Sell licenses for this software is strictly forbidden.
//  ¥	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  ¥	Neither the name of the Flying Pig SARL nor the names of any Flying Pig products using this software, including Edouard(R),
//  nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
//  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FPConnection.h"
#import "libpq-fe.h"
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <arpa/inet.h>

//Connection Defines
#define	FPConnectionParams											@"hostaddr = '%@' user = '%@' password = '%@' dbname = '%@' port = '%ld'"
#define	FPConnectionSSLParam										@" sslmode = require"
#define	FPConnectionDefaultPort										5432
#define	FPConnectionLocalhost										@"localhost"
#define	FPConnectionLocalhostAddress								@"127.0.0.1"

//Cancel
#define FPPSQLCancelErrorBufferSize									256

//Connection status
#define FPConnectionStatusConnectionOk								@"Connection OK"
#define FPConnectionStatusConnectionBad								@"Connection BAD"
#define FPConnectionStatusConnectionNeeded							@"Connection needed"
#define FPConnectionStatusConnectionWaiting							@"Waiting for connection to be made"
#define FPConnectionStatusConnectionOkWaiting						@"Connection OK; Waiting to send"
#define FPConnectionStatusConnectionWaitingForResponse				@"Waiting for a response from the server"
#define FPConnectionStatusConnectionReceivedAuthWaiting				@"Received authentification; Waiting for backend start-up to finish"
#define FPConnectionStatusConnectionNegotiatingSSL					@"Negotiating SSL encryption"
#define FPConnectionStatusConnectionNegotiatingEnv					@"Negotiating environment-driven paramete settings"
#define FPConnectionStatusConnectionNoMessageCode					@"No message code, return value : %d"
#define FPConnectionStatusConnectionNoMessage						@"No message"





@implementation FPConnection


#pragma mark Properties
@synthesize connection = _connection;
@synthesize lock = _lock;
@synthesize hostString = _hostString;
@synthesize loginString = _loginString;
@synthesize passwordString = _passwordString;
@synthesize dbString = _dbString;
@synthesize portInteger = _portInteger;
@synthesize sslSupportBool = _sslSupportBool;


#pragma mark Init/Dealloc
- (id)init
{
		self = [super init];
	if (self)
	{
		_hostString = nil;
		_loginString = nil;
		_passwordString = nil;
		_dbString = nil;		
		_portInteger = FPConnectionDefaultPort;
		_connection = NULL;
		_sslSupportBool = NO;
		_lock = nil;
	}
	return self;
}

- (id)initWithHost:(NSString *)host
		 withLogin:(NSString *)login
	  withPassword:(NSString *)password
			withDb:(NSString *)db
		  withPort:(NSUInteger)port
		   withSSL:(BOOL)sslSupport
		  withLock:(NSLock *)theLock
{
		self = [super init];
	if (self)
	{
		self.hostString = host;
		self.loginString = login;
		self.passwordString = password;
		self.dbString = db;
		self.portInteger = port;
		self.sslSupportBool = sslSupport;
		_connection = NULL;	
		self.lock = theLock;
	}
	return self;
}

- (void)dealloc
{
	[_hostString release];
	[_loginString release];
	[_passwordString release];
	[_dbString release];
	[self closeConnection];
	[_lock release];
	[super dealloc];
}


#pragma mark Setters / Getters
- (NSString *)hostString
{
	return _hostString;
}

- (void)setHostString:(NSString *)host
{
	NSString	*toBeReleased = _hostString;
	
	//Localhost case
	if ([host isEqualToString:FPConnectionLocalhost]) 
	{
		_hostString = [[NSString alloc] initWithString:FPConnectionLocalhostAddress];
	} 
	else 
	{
		struct addrinfo hints, *res;
		int errcode;
		char addrstr[100];
		void *ptr;
		const char *cHost = [host cStringUsingEncoding:NSUTF8StringEncoding];
		
		memset (&hints, 0, sizeof (hints));
		hints.ai_family = PF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_flags |= AI_CANONNAME;
		
		// get the address info in struct
		errcode = getaddrinfo (cHost, NULL, &hints, &res);
		if (errcode != 0)
		{
			NSLog(@"FPPostGreSQL: error in getaddrinfo: %s\n", gai_strerror(errcode));
			_hostString = [host retain];
		}
		else	
		{			
			while (res)
			{
				// transform into readable address
				inet_ntop(res->ai_family, res->ai_addr->sa_data, addrstr, 100);
				
				switch (res->ai_family)
				{
					case AF_INET:
						ptr = &((struct sockaddr_in *) res->ai_addr)->sin_addr;
						break;
					case AF_INET6:
						ptr = &((struct sockaddr_in6 *) res->ai_addr)->sin6_addr;
						break;
				}
				inet_ntop (res->ai_family, ptr, addrstr, 100);
#ifdef PG_DEBUG
				NSLog(@"IPv%d address: %s (%s)\n", res->ai_family == PF_INET6 ? 6 : 4,
						addrstr, res->ai_canonname);
#endif
				_hostString = [[NSString alloc] initWithFormat:@"%s", addrstr];

				res = res->ai_next;
			}
			
		}
	}   
	
	if (toBeReleased)
		[toBeReleased release];
}


#pragma mark Connection
- (BOOL)connect
{
	if ([self checkThisConnection])
		return NO;
	
	NSMutableString		*connectParams = [[NSMutableString alloc] initWithFormat:FPConnectionParams,
										  _hostString,
										  _loginString,
										  _passwordString,
										  _dbString,
										  _portInteger];
	
	//Add the SSL support if it's needed
	if (_sslSupportBool) 
	{
		PQinitSSL(1);
		[connectParams appendFormat:@"%@", FPConnectionSSLParam];
	}
	
	//Create the new one
	[self.lock lock];
	_connection = PQconnectdb([connectParams cStringUsingEncoding:NSUTF8StringEncoding]);	
	[self.lock unlock];
	
	[connectParams release];

	BOOL connectionWorked = [self checkThisConnection];

	if (!connectionWorked)
	{
		NSLog(@"Connection to Database failed: %s", PQerrorMessage(_connection));
	}
	
	return connectionWorked;
}

- (void)closeConnection
{
	if ([self checkThisConnection]) {
		[self.lock lock];
		PQfinish(_connection);
		[self.lock unlock];
	}	
	_connection = NULL;
}

- (BOOL)reconnect
{
	[self closeConnection];
	return [self connect];	
}

- (void)reset
{
	[self.lock lock];
	PQreset(_connection);
	[self.lock unlock];
}

- (ConnStatusType)status
{
	ConnStatusType connectionsStatus;
	
	[self.lock lock];
	connectionsStatus = PQstatus(_connection);
	[self.lock unlock];
	
	return connectionsStatus;
}

- (BOOL)cancel
{
	char		error[FPPSQLCancelErrorBufferSize];
	PGcancel	*cancel;
	NSInteger	returnCode = 0;
	
	[self.lock lock];
	cancel = PQgetCancel(_connection);
	returnCode = PQcancel(cancel, error, FPPSQLCancelErrorBufferSize);
	[self.lock unlock];
	
	if (!returnCode) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%s", __FILE__, error);
#endif
		
		PQfreeCancel(cancel);		
		return NO;
	}
	PQfreeCancel(cancel);
	return YES;
}


#pragma mark Check Connections Status
- (BOOL)checkThisConnection
{
	BOOL	isConnectionOk = YES;
 
	[self.lock lock];	
	if (_connection == NULL)
		isConnectionOk = NO;
	[self.lock unlock];
	
	if (isConnectionOk == NO)
		return NO;
	
	switch([self status]) {			
		case CONNECTION_OK:
			return YES;
		case CONNECTION_BAD:
			return NO;
		case CONNECTION_NEEDED:
			return YES;
		case CONNECTION_STARTED:
			return NO;
		case CONNECTION_MADE:
			return YES;
		case CONNECTION_AWAITING_RESPONSE:
			return NO;
		case CONNECTION_AUTH_OK:
			return YES;
		case CONNECTION_SSL_STARTUP:
			return NO;
		case CONNECTION_SETENV:
			return NO;
		default:
			return NO;
	}
	return NO;
}

//Check the connection and returns a NSString
- (NSString *)checkThisConnectionWithFeedback
{
	switch([self status])
	{
		case CONNECTION_OK:
			return FPConnectionStatusConnectionOk;
		case CONNECTION_BAD:
			return FPConnectionStatusConnectionBad;
		case CONNECTION_NEEDED:
			return FPConnectionStatusConnectionNeeded;
		case CONNECTION_STARTED:
			return FPConnectionStatusConnectionWaiting;
		case CONNECTION_MADE:
			return FPConnectionStatusConnectionOkWaiting;
		case CONNECTION_AWAITING_RESPONSE:
			return FPConnectionStatusConnectionWaitingForResponse;
		case CONNECTION_AUTH_OK:
			return FPConnectionStatusConnectionReceivedAuthWaiting;
		case CONNECTION_SSL_STARTUP:
			return FPConnectionStatusConnectionNegotiatingSSL;
		case CONNECTION_SETENV:
			return FPConnectionStatusConnectionNegotiatingEnv;
		default:
			return [NSString stringWithFormat:FPConnectionStatusConnectionNoMessageCode, [self status]];
	}
	return FPConnectionStatusConnectionNoMessage;
}


@end
