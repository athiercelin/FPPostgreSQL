//
//  FPRequestOperation.m
//  FPPostgreSQL
//
//  Created by Flying Pig on 5/20/08.
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

#import "FPRequestOperation.h"

#import "FPConnection.h"
#import "FPRequest.h"



@interface FPRequestOperation (Private)

//Execute Request
- (NSInteger)execRequestWithResults:(PGresult **)pgresult;

@end

@implementation FPRequestOperation (Private)


#pragma mark Execute Request
- (NSInteger)execRequestWithResults:(PGresult **)pgresult
{
	NSInteger		returnCode = 1;
	NSRunLoop		*currentLoop = [NSRunLoop currentRunLoop];
	
	returnCode = PQsendQuery(self.connection.connection, [_requestString cStringUsingEncoding:NSUTF8StringEncoding]);
	while (!returnCode && ![self isCancelled] && [currentLoop runMode:NSDefaultRunLoopMode
														   beforeDate:[NSDate distantFuture]])
		;
	
	//Is Cancelled
	if ([self isCancelled])
		return -1;
	
	//Request failed
	if (!returnCode)
		return returnCode;
	
	//Get Results
	while ((*pgresult = PQgetResult(self.connection.connection))) 
	{
		//Is Cancelled
		if ([self isCancelled])
			return -1;		
		
		//Get "INSERT / DELETE / UPDATE" request
		if (![self editedRequestWithResults:*pgresult]) 
		{	
			//Get "SELECT" request
			[self selectedRequestWithResults:*pgresult];
		}
	}
	
	return returnCode;
}

@end





@implementation FPRequestOperation


#pragma mark Properties
@synthesize requestString = _requestString;
@synthesize returnShortRequest = _returnShortRequest;

#pragma mark Init / Dealloc
- (id)init
{
		self = [super init];
	if (self)
	{
		_requestString = nil;
		_returnShortRequest = YES;
	}
	return self;
}

- (id)initWithConnection:(FPConnection *)theConnection
			 withRequest:(NSString *)request 
		  withIdentifier:(NSString *)identifier 
		withNotification:(NSString *)notification
			withMetadata:(NSDictionary *)metadata
			withPriority:(FPRequestQueuePriority)priority
				withLock:(NSLock *)lock
{
	self = [self init];
	if (self){
		self.connection = theConnection;
		self.identifierString = identifier;
		self.notificationString = notification;
		self.metadataDictionary = metadata;
		self.requestString = request;
		self.lock = lock;
		[self setQueuePriority:priority];
	}
	return self;
}

- (void)dealloc
{
	[_requestString release];
	[super dealloc];
}


#pragma mark NSOperation Implementation
- (void)main
{
	NSAutoreleasePool		*pool = [NSAutoreleasePool new];
	
	@try 
	{
		PGresult				*pgresult = NULL;
		NSInteger				returnCode = 0;
		
#ifdef PG_DEBUG
		NSLog(@"%s: requestString:\n%@", __FILE__, _requestString);
#endif	
		
		//Is Cancelled
		if ([self isCancelled]) 
		{
			[self finishOperationWithRequest:_requestString
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Check connection
		if (![self.connection checkThisConnection]) 
		{		
			[self finishOperationWithRequest:_requestString
								   withError:FPPSQLConnectionFailed];
			return;
		}
		
		//Is Cancelled
		if ([self isCancelled]) 
		{
			[self finishOperationWithRequest:_requestString
								   withError:FPPSQLOperationCancelled];
			return;
		}	
		
		//Exec the request
		[self.lock lock];
		returnCode = [self execRequestWithResults:&pgresult];	
		[self.lock unlock];
		
		//Is cancelled
		if (returnCode == -1) 
		{
			[self.connection cancel];
			[self finishOperationWithRequest:_requestString
								   withError:FPPSQLOperationCancelled];
			if (pgresult)
				PQclear(pgresult);
			return;
		}
		
		//Error
		if (!returnCode) 
		{		
			NSString	*errorString = nil;
			char		*errorMessage = NULL;
			
			[self.lock lock];
			errorMessage = PQerrorMessage(self.connection.connection);
			if (errorMessage)
				errorString = [NSString stringWithCString:(const char *)errorMessage encoding:NSUTF8StringEncoding];
			[self.lock unlock];		
			
			if (!errorString)
				errorString = FPPSQLExecutionFailed;		
			[self finishOperationWithRequest:_requestString
								   withError:errorString];
			if (pgresult)
				PQclear(pgresult);
			return;
		}
	
		
	}
	@catch (NSException *e)
	{
	
#if defined LOG || defined DEBUG
		NSLog(@"%s: \n %@\n%@", __FILE__, [e name], [e reason]);
#endif		
		
		@throw;
		
	}
	@finally 
	{
		[pool release];
	}
}


#pragma mark Get Results
//Get the result from an "UPDATE, DELETE OR INSERT" request
- (BOOL)editedRequestWithResults:(PGresult *)pgresult
{
	NSDictionary			*results = nil;
	NSMutableDictionary		*resultsMutableDic = nil;
	
	if ((results = [FPRequest getResultsFromEditRequestWithPGResult:pgresult])) 
	{
		resultsMutableDic = [[NSMutableDictionary alloc] initWithDictionary:results copyItems:YES];
		[results release];
		if (self.returnShortRequest && [_requestString length] > 4096)
			[resultsMutableDic setObject:[_requestString substringToIndex:4096] forKey:self.identifierString];
		else
			[resultsMutableDic setObject:_requestString forKey:self.identifierString];
		if (self.metadataDictionary)
			[resultsMutableDic setObject:self.metadataDictionary forKey:FPPSQLResultsMetadata];
		
		FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:resultsMutableDic];

		[resultsMutableDic release];
		
		result.request = _requestString;
		result.requestIdentifier = self.identifierString;

#ifdef __FPPG_RETURNS_IN_BG
		[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[ self.notificationString,  result]];
#else
		[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:) withObject:@[ self.notificationString,  result] waitUntilDone:NO];
#endif
		PQclear(pgresult);
		return YES;
	}
	return NO;
}

//Get the result from a "SELECT" request
- (void)selectedRequestWithResults:(PGresult *)pgresult
{
	NSDictionary			*results = nil;
	NSMutableDictionary		*resultsMutableDic = nil;
	
	results = [FPRequest getResultsFromSelectRequestWithPGResult:pgresult];	
	resultsMutableDic = [[NSMutableDictionary alloc] initWithDictionary:results copyItems:YES];
	[results release];
	if (self.returnShortRequest && [_requestString length] > 4096)
		[resultsMutableDic setObject:[_requestString substringToIndex:4096] forKey:self.identifierString];
	else
		[resultsMutableDic setObject:_requestString forKey:self.identifierString];
	if (self.metadataDictionary)
		[resultsMutableDic setObject:self.metadataDictionary forKey:FPPSQLResultsMetadata];
	
	FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:resultsMutableDic];
	[resultsMutableDic release];
	
	result.request = _requestString;
	result.requestIdentifier = self.identifierString;
#ifdef __FPPG_RETURNS_IN_BG
	[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[ self.notificationString,  result]];
#else
	[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:) withObject:@[ self.notificationString,  result] waitUntilDone:NO];
#endif
	
	PQclear(pgresult);
}


@end
