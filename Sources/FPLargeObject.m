//
//  FPLargeObject.m
//  FPPostgreSQL
//
//  Created by Flying Pig on 5/21/08.
//  Copyright © 2008 Flying Pig. All rights reserved.
//
//  Redistribution and use in binary form, without modification, are permitted provided that the following conditions are met:
//  •	Redistributions in binary form must not be under any other license or conditions other than the ones described in this notice.
//  •	Sell licenses for this software is strictly forbidden.
//  •	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  •	Neither the name of the Flying Pig SARL nor the names of any Flying Pig products using this software, including Edouard(R),
//  nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
//  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FPLargeObject.h"

#import "FPConnection.h"


//Transactions
#define	FPPSQLBeginSqlTransaction												"begin"
#define	FPPSQLEndSqlTransaction													"end"

//Buffer Size
#define FPLargeObjectBufferSize													504800



@interface FPLargeObject (Private)

//Transaction
- (NSString *)launchTransactionWithString:(NSString *)request;

@end


@implementation FPLargeObject (Private)


#pragma mark Transaction
- (NSString *)launchTransactionWithString:(NSString *)request
{
	PGresult		*pgReturnedValue;
	NSString 		*reason = nil;
	
	[_lock lock];
	pgReturnedValue = PQexec(_connection.connection, [request cStringUsingEncoding:NSUTF8StringEncoding]);	
	[_lock unlock];	
	
	if (PQresultStatus(pgReturnedValue) == PGRES_FATAL_ERROR) 
	{
		//NSException		*loselectBeginException = nil;
		
		[_lock lock];
		reason = [NSString stringWithFormat:@"%s", PQerrorMessage(_connection.connection)];
		[_lock unlock];
		
		/*
		 loselectBeginException = [NSException exceptionWithName:LOSELECTBEGINEXCEPTION
		 reason:reason
		 userInfo:nil];
		 @throw loselectBeginException;
		 return nil;
		 */
		
#ifdef PG_DEBUG			 
		NSLog(@"Failed To Load LO - %s: %@", __FILE__, reason);		
#endif
		
	}
	PQclear(pgReturnedValue);
	return reason;
}

@end




@implementation FPLargeObject


#pragma mark Class methods



+ (NSString *)beginLargeObjectWithConnection:(FPConnection *)connection
									withLock:(NSLock *)theLock
{
	FPLargeObject	*largeObject = [[[FPLargeObject alloc] initWithConnection:connection withLock:theLock] autorelease];
	
	return [largeObject beginLargeObject];
}

+ (NSString *)endLargeObjectWithConnection:(FPConnection *)connection
								  withLock:(NSLock *)theLock
{
	FPLargeObject	*largeObject = [[[FPLargeObject alloc] initWithConnection:connection withLock:theLock] autorelease];
	
	return [largeObject endLargeObject];
	
}


#pragma mark Init / Dealloc
- (id)init
{
		self = [super init];
	if (self){
		_connection = nil;
		_lock = nil;
	}
	return self;
}

- (id)initWithConnection:(FPConnection *)connection
				withLock:(NSLock *)theLock
{
		self = [super init];
	if (self){
		_connection = [connection retain];
		_lock = [theLock retain];
	}
	return self;
}

- (void)dealloc
{
	[_connection release];
	[_lock release];
	[super dealloc];
}


#pragma mark Transactions
- (NSString *)beginLargeObject
{
	return [self launchTransactionWithString:[NSString stringWithFormat:@"%s", FPPSQLBeginSqlTransaction]];
}

- (NSString *)endLargeObject
{
	return [self launchTransactionWithString:[NSString stringWithFormat:@"%s", FPPSQLEndSqlTransaction]];	
}


#pragma mark Read Large Objects
- (NSData *)readLargeObjectWithFd:(NSInteger)fd
{
	char				readBuf[FPLargeObjectBufferSize];
	NSInteger			readCount = 0;
	NSInteger			bufferCounter = 0;
	NSInteger			readBufferCounter = 0;
	char				*buffer = NULL;
	char				*tmpBuffer = NULL;
	NSInteger			bufLen = 0;
	NSInteger			lastLen = 0;
	NSData				*data = nil;
		
	//Read
	do {
		bzero(readBuf, FPLargeObjectBufferSize);
		
		[_lock lock];
		readCount = lo_read(_connection.connection, fd, readBuf, FPLargeObjectBufferSize);
		[_lock unlock];
		
#ifdef PG_DEBUG			 
		//NSLog(@"%s: buffer:%s\treadCount:%d", __FILE__, buffer, readCount);		
#endif
		
		if (readCount <= 0)
			break;		
		
		lastLen = bufLen;
		bufLen += readCount;
		
		tmpBuffer = buffer;
		if ((buffer = malloc(sizeof(char) * (bufLen + 1))) == NULL) {
			if (lastLen)
				free(tmpBuffer);
			return nil;
		}
		
		for (bufferCounter = 0; bufferCounter < lastLen; bufferCounter++)
			buffer[bufferCounter] = tmpBuffer[bufferCounter];		
		
		if (lastLen)
			free(tmpBuffer);
		
		for (bufferCounter = lastLen, readBufferCounter = 0; bufferCounter < bufLen &&
			 readBufferCounter < readCount; bufferCounter++, readBufferCounter++)
			buffer[bufferCounter] = readBuf[readBufferCounter];
		
	} while (readCount > 0);
	data = [[NSData alloc] initWithBytes:buffer length:bufLen];
	free(buffer);
	return data;
}

@end
