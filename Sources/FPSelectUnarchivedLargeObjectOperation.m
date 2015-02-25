//
//  FPSelectUnarchivedLargeObjectOperation.m
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

#import "FPSelectUnarchivedLargeObjectOperation.h"

#import "FPConnection.h"
#import "libpq-fs.h"
#import "FPLargeObject.h"


#define FPSelectLargeObjectOperationUnarchiveError								@"Can't unarchive the NSData"




@implementation FPSelectUnarchivedLargeObjectOperation


#pragma mark NSOperation Implementation
- (void)main
{
	NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	
	@try {
		NSInteger			fd = 0;
		NSInteger			closeStatus = 0;
		NSString			*reason = nil;
		FPLargeObject		*largObject = [[FPLargeObject alloc] initWithConnection:self.connection
																	  withLock:self.lock];
		NSData				*data = nil;
		id					object = nil;
		
		//Is Cancelled
		if ([self isCancelled]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Check connection
		if (![self.connection checkThisConnection]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPPSQLConnectionFailed];
			return;
		}
		
		//Is Cancelled
		if ([self isCancelled]) {
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Begin Transaction
		if ((reason = [largObject beginLargeObject])) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, reason);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:reason];
			[largObject release];
			return;
		}		
		
		//Open
		[self.lock lock];
		fd = lo_open(self.connection.connection, self.oid, INV_READ|INV_WRITE);	
		[self.lock unlock];	
		
		if (fd < 0) {
			
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationBadFd);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPSelectLargeObjectOperationBadFd];
			
			//End Transaction
			[largObject endLargeObject];
			[largObject release];
			return;
			
			/*
			 // close connection	
			 NSException		*loopenException = [NSException exceptionWithName:LOSELECTOPENEXCEPTION
			 reason:LOSELECTOPENEXCEPTIONREASON
			 userInfo:nil];
			 
			 @throw loopenException;
			 return nil;
			 */
		}
		
		//Read
		if ((data = [largObject readLargeObjectWithFd:fd]) == nil) {
			
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationDataError);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPSelectLargeObjectOperationDataError];
			
			//End Transaction
			[largObject endLargeObject];
			[largObject release];
			return;		
		}
		
		//Close
		[self.lock lock];
		closeStatus = lo_close(self.connection.connection, fd);
		[self.lock unlock];
		
		if (closeStatus < 0) {
			
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationCloseError);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPSelectLargeObjectOperationDataError];
			[data release];
			
			//End Transaction
			[largObject endLargeObject];
			[largObject release];
			return;
			
			/*
			 // close connection
			 NSException		*locloseException = [NSException exceptionWithName:LOSELECTCLOSEEXCEPTION
			 reason:LOSELECTCLOSEEXCEPTIONREASON
			 userInfo:nil];
			 @throw locloseException;
			 return nil;
			 */
		}
		
		//End Transaction
		if ((reason = [largObject endLargeObject])) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, reason);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:reason];
			[data release];
			[largObject release];
			return;
		}		
		
		//Unarchive the Object from the NSData
		@try 
		{
			object = [NSKeyedUnarchiver unarchiveObjectWithData:data];	
		}	
		@catch (NSException *exception) 
		{
#if defined LOG || defined DEBUG
			NSLog(@"%s:%@%@", __FILE__, [exception name], [exception reason]);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", self.oid]
								   withError:FPSelectLargeObjectOperationUnarchiveError];
			[data release];
			[largObject release];
			return;		
		}
		
		//Send the results
		[self finishOperationWithRequest:[NSNumber numberWithInt:self.oid]
							   withError:nil
							  withResult:object];
		[data release];
		[largObject release];
		
	} @catch (NSException *e) {
		
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [e name], [e reason]);
#endif		

		@throw;
	
	} @finally {
		[pool release];
	}	
}

@end
