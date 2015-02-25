//
//  FPOperation.m
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

#import "FPOperation.h"

#import "FPConnection.h"
#import "FPPSQLResult.h"


@implementation FPOperation


#pragma mark Properties
@synthesize connection = _connection;
@synthesize lock = _lock;
@synthesize identifierString = _identifierString;
@synthesize notificationString = _notificationString;
@synthesize metadataDictionary = _metadataDictionary;


#pragma mark Init / Dealloc
- (id)init
{
		self = [super init];
	if (self){	
		_startingThread = [NSThread currentThread];
		_lock = [NSLock new];
		_connection = nil;
		_identifierString = nil;
		_notificationString = nil;
		_metadataDictionary = nil;
		self.pgsqlCore = nil;
	}
	return self;
}

- (void)dealloc
{
	[_connection release];
	[_identifierString release];
	[_notificationString release];
	[_metadataDictionary release];
	[_lock release];
	[super dealloc];
}


#pragma mark Finish Operation
- (void)finishOperationWithRequest:(id)request
						 withError:(NSString *)error
{
	NSMutableDictionary	*mutableResults = [NSMutableDictionary new];
	
	if (request)
		[mutableResults setObject:request forKey:self.identifierString];
	if (error)
		[mutableResults setObject:error forKey:FPPSQLResultsError];
	if (self.metadataDictionary)
		[mutableResults setObject:self.metadataDictionary forKey:FPPSQLResultsMetadata];
	
	FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:mutableResults];
	[mutableResults release];
	
	result.request = request;
	result.requestIdentifier = self.identifierString;
	
#ifdef PG_DEBUG
	if (error)
		NSLog(@"%s:%@", __FILE__, error);
#endif
	
#ifdef __FPPG_RETURNS_IN_BG
	[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[self.notificationString, result]];
#else
	[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:)
			   withObject:@[self.notificationString,result]
			waitUntilDone:NO];
#endif
}

- (void)finishOperationWithRequest:(id)request
						 withError:(NSString *)error
						withResult:(id)result
{
	NSMutableDictionary	*mutableResults = [NSMutableDictionary new];
	
	if (request)
		[mutableResults setObject:request forKey:self.identifierString];
	if (error)
		[mutableResults setObject:error forKey:FPPSQLResultsError];
	if (result)
		[mutableResults setObject:result forKey:FPPSQLResults];
	if (self.metadataDictionary)
		[mutableResults setObject:self.metadataDictionary forKey:FPPSQLResultsMetadata];
	
	FPPSQLResult *resultObj = [[FPPSQLResult alloc] initWithLegacyDictionary:mutableResults];
	[mutableResults release];
	
	resultObj.request = request;
	
#ifdef PG_DEBUG
	if (error)
		NSLog(@"%s:%@", __FILE__, error);
#endif
	
#ifdef __FPPG_RETURNS_IN_BG
	[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[self.notificationString, resultObj]];
#else
	[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:)
			   withObject:@[self.notificationString, resultObj]
			waitUntilDone:NO];
#endif
}

- (void)postNotifWithObjectArray:(NSArray *)objArray
{
	NSString *notificationName = [objArray objectAtIndex:0];
	FPPSQLResult *object = [objArray objectAtIndex:1];
	
	// FIXME: It would be better for performance to have a locking mecanism only on sections of plugins that can be called several times in a row
	if ([notificationName isEqualToString:FPPSQLTargetSelectorDefaultNotif])
	{
		// direct target/selector system. NB: locked inside 
		[self.pgsqlCore targetSelectorCatcher:object];
	}
	else
	{
		// legacy system using notifications
//		[_lock lock];
		[[NSNotificationCenter defaultCenter] postNotificationName:notificationName
															object:object
														  userInfo:nil];
//		[_lock unlock];
	}
}


@end
