//
//  FPDeleteLargeObjectOperation.m
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

#import "FPDeleteLargeObjectOperation.h"

#import "FPConnection.h"
#import "FPLargeObject.h"



@implementation FPDeleteLargeObjectOperation


#pragma mark Properties
@synthesize oid = _oid;


#pragma mark Init / Dealloc
- (id)init
{
		self = [super init];
	if (self){
		_oid = InvalidOid;
	}
	return self;
}

- (id)initWithConnection:(FPConnection *)theConnection
				 withOid:(Oid)oidValue
		  withIdentifier:(NSString *)identifier
		withNotification:(NSString *)notification
			withMetadata:(NSDictionary *)metadata
			withPriority:(FPRequestQueuePriority)priority
				withLock:(NSLock *)theLock
{
		self = [super init];
	if (self){
		self.oid = oidValue;
		self.identifierString = identifier;
		self.notificationString = notification;
		self.connection = theConnection;
		self.metadataDictionary = metadata;
		self.lock = theLock;
		[self setQueuePriority:priority];
	}
	return self;
}



#pragma mark NSOperation Implementation
- (void)main
{
	NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	
	@try {
		NSInteger			returnCode = 0;
		NSString			*reason = nil;
		FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:self.connection
																	   withLock:self.lock];
		//Is Cancelled
		if ([self isCancelled]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Check connection
		if (![self.connection checkThisConnection]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:FPPSQLConnectionFailed];
			return;
		}
		
		//Is Cancelled
		if ([self isCancelled]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Begin Transaction
		if ((reason = [largeObject beginLargeObject])) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, reason);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:reason];
			[largeObject release];
			return;
		}		
		
		//Unlink
		[self.lock lock];
		returnCode = lo_unlink(self.connection.connection, _oid);
		[self.lock unlock];
		
		if (returnCode < 0) {
			
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPDeleteLargeObjectOperationDeleteError);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:FPDeleteLargeObjectOperationDeleteError];
			[largeObject endLargeObject];
			[largeObject release];
			return;
		}
		
		//End Transaction
		if ((reason = [largeObject endLargeObject])) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, reason);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", _oid]
								   withError:reason];
			[largeObject release];
			return;
		}		
		
		//Send the results
		[self finishOperationWithRequest:[NSNumber numberWithInt:_oid]
							   withError:nil
							  withResult:nil];
		[largeObject release];		
		
	} @catch (NSException *e) {

#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [e name], [e reason]);
#endif		
		
		@throw;
	}
	@finally {
		[pool release];
	}
}

@end
