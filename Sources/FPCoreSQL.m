//
//  FPCoreSQL.m
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

#import "FPCoreSQL.h"

#import "FPCreateLargeObjectOperation.h"
#import "FPSelectLargeObjectOperation.h"
#import "FPUpdateLargeObjectOperation.h"
#import "FPDeleteLargeObjectOperation.h"
#import "FPSelectUnarchivedLargeObjectOperation.h"



@implementation FPCoreSQL


#pragma mark Asynchronous Connection
- (void)connectWithIdentifier:(NSString *)identifier 
			 withNotification:(NSString *)notification
{
	[super connectWithIdentifier:identifier
				 withNotification:notification 
				withDependencies:nil
					withMetadata:nil
					withPriority:FPRequestQueuePriorityVeryHigh];
}

- (void)reconnectWithIdentifier:(NSString *)identifier 
			   withNotification:(NSString *)notification
{
	[super reconnectWithIdentifier:identifier
				  withNotification:notification 
				  withDependencies:nil
					  withMetadata:nil
					  withPriority:FPRequestQueuePriorityVeryHigh];	
}

- (void)closeConnectionWithIdentifier:(NSString *)identifier 
					 withNotification:(NSString *)notification
{
	[super closeConnectionWithIdentifier:identifier
						withNotification:notification 
						withDependencies:nil
							withMetadata:nil
							withPriority:FPRequestQueuePriorityVeryHigh];	
}


#pragma mark Asynchronous Request methods
- (void)execRequest:(NSString *)request withIdentifier:(NSString *)identifier withNotification:(NSString *)notification
{
	[self execRequest:request
	   withIdentifier:identifier
	 withNotification:notification
	 withDependencies:nil
		 withMetadata:nil];
}

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier 
   withNotification:(NSString *)notification
   withDependencies:(NSArray *)dependencies
       withMetadata:(NSDictionary *)metadata
{
	[super execRequest:request
		withIdentifier:identifier
	  withNotification:notification
	  withDependencies:dependencies
		  withMetadata:metadata
		  withPriority:FPRequestQueuePriorityNormal];	
}

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
{
	[self execRequest:request
	   withIdentifier:identifier
		   withTarget:target
		 withSelector:selector
	 withDependencies:nil
		 withMetadata:nil];
}

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
   withDependencies:(NSArray *)dependencies
	   withMetadata:(NSDictionary *)metadata
{
	[super execRequest:request
		withIdentifier:identifier
			withTarget:target
		  withSelector:selector
	  withDependencies:dependencies
		  withMetadata:metadata
		  withPriority:FPRequestQueuePriorityNormal];
}

#pragma mark Asynchronous Large Objects methods with auto Archiver and Unarchiver
- (void)createLargeObjectWithUnarchivedObject:(id)object
							   withIdentifier:(NSString *)identifier
							 withNotification:(NSString *)notification
{
	[self createLargeObjectWithUnarchivedObject:object
								 withIdentifier:identifier
							   withNotification:notification
							   withDependencies:nil
								   withMetadata:nil];
}

- (void)createLargeObjectWithUnarchivedObject:(id)object
							   withIdentifier:(NSString *)identifier
							 withNotification:(NSString *)notification
							 withDependencies:(NSArray *)dependencies
								 withMetadata:(NSDictionary *)metadata
{
	NSData			*data = nil;
	
	@try 
	{
		data = [NSKeyedArchiver archivedDataWithRootObject:object];
	}	
	@catch (NSException *exception) 
	{
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
		
		
		NSDictionary	*results = [[NSDictionary alloc] initWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", InvalidOid], identifier, 
									FPCreateLargeObjectOperationInvalidOid, FPPSQLResultsError,
									metadata, FPPSQLResultsMetadata, nil];
		
		FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:results];
		[results release];
		
		//		result.request = request;
		//		result.requestIdentifier = self.identifierString;
#ifdef __FPPG_RETURNS_IN_BG
		[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[notification, result]];
#else
		[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:) withObject:@[notification, result] waitUntilDone:NO];
#endif

		return;
	}
	
	[super createLargeObjectWithData:data 
					  withIdentifier:identifier 
					withNotification:notification
					withDependencies:dependencies
						withMetadata:metadata 
						withPriority:NSOperationQueuePriorityNormal];
}

- (void)selectUnarchivedLargeObjectWithOid:(Oid)oidValue
							withIdentifier:(NSString *)identifier
						  withNotification:(NSString *)notification
{
	[self selectUnarchivedLargeObjectWithOid:oidValue
							  withIdentifier:identifier
							withNotification:notification
							withDependencies:nil
								withMetadata:nil];
}

- (void)selectUnarchivedLargeObjectWithOid:(Oid)oidValue
							withIdentifier:(NSString *)identifier
						  withNotification:(NSString *)notification
						  withDependencies:(NSArray *)dependencies
							  withMetadata:(NSDictionary *)metadata
{
	FPSelectUnarchivedLargeObjectOperation	*operation = [[FPSelectUnarchivedLargeObjectOperation alloc] initWithConnection:self.connection 
																												   withOid:oidValue 
																											withIdentifier:identifier 
																										  withNotification:notification 
																											  withMetadata:metadata 
																											  withPriority:FPRequestQueuePriorityNormal
																												  withLock:self.lock];
	
	if (dependencies)
		[super setDependencies:dependencies
				  forOperation:operation];
	[self.operationQueue addOperation:operation];
	[operation release];	
}

- (void)updateLargeObjectWithOid:(Oid)oidValue
			withUnarchivedObject:(id)object
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
{
	[self updateLargeObjectWithOid:oidValue
			  withUnarchivedObject:object
					withIdentifier:identifier
				  withNotification:notification
				  withDependencies:nil
					  withMetadata:nil];
}

- (void)updateLargeObjectWithOid:(Oid)oidValue
			withUnarchivedObject:(id)object
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
{
	NSData			*data = nil;
	
	@try {
		data = [NSKeyedArchiver archivedDataWithRootObject:object];
	}	
	@catch (NSException *exception) {
		
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
		
		
		NSDictionary	*results = [[NSDictionary alloc] initWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", oidValue], identifier, 
									FPUpdateLargeObjectOperationBadFd, FPPSQLResultsError,
									metadata, FPPSQLResultsMetadata, nil];

		FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:results];
		[results release];
		
//		result.request = request;
//		result.requestIdentifier = self.identifierString;
#ifdef __FPPG_RETURNS_IN_BG
		[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[notification, result]];
#else
		[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:) withObject:@[notification, result] waitUntilDone:NO];
#endif
		return;
	}
	
	[super updateLargeObjectWithOid:oidValue 
						   withData:data 
					 withIdentifier:identifier 
				   withNotification:notification 
				   withDependencies:dependencies
					   withMetadata:metadata 
					   withPriority:NSOperationQueuePriorityNormal];
}

- (void)removeLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
{
	[self removeLargeObjectWithOid:oidValue
					withIdentifier:identifier
				  withNotification:notification
				  withDependencies:nil
					  withMetadata:nil]; 
}

- (void)removeLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
{
	[super removeLargeObjectWithOid:oidValue
					 withIdentifier:identifier 
				   withNotification:notification 
				   withDependencies:dependencies
					   withMetadata:metadata 
					   withPriority:FPRequestQueuePriorityNormal];
}


#pragma mark Synchronous Large Objects methods with auto Archiver and Unarchiver
- (Oid)createLargeObjectWithUnarchivedObject:(id)object
{
	NSData			*data = nil;
	
	@try {
		data = [NSKeyedArchiver archivedDataWithRootObject:object];
	}	
	@catch (NSException *exception) {
		
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
		
		return InvalidOid;
	}
	
	if (data == nil)
		return InvalidOid;
	
	return [super createLargeObjectWithData:data];
}

- (id)selectUnarchivedLargeObjectWithOid:(Oid)oidValue;
{
	NSData		*data = [super selectLargeObjectWithOid:oidValue];
	id			object = nil;	
	
	if (data == nil)
		return nil;
	
	@try {
		object = [[NSKeyedUnarchiver unarchiveObjectWithData:data] retain];
	}	
	@catch (NSException *exception) {
		
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
		
		return nil;
	}
	return object;
}

- (BOOL)updateLargeObjectWithOid:(Oid)oidValue
			withUnarchivedObject:(id)object
{
	NSData	*data = nil;
	
	@try {
		data = [NSKeyedArchiver archivedDataWithRootObject:object];
	}	
	@catch (NSException *exception) {
		
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
		
		return NO;
	}
	
	if (data == nil)
		return NO;		
	
	return [super updateLargeObjectWithOid:oidValue withData:data];
}

@end
