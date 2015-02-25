//
//  FPCreateLargeObjectOperation.m
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

#import "FPCreateLargeObjectOperation.h"

#import "FPConnection.h"
#import "libpq-fs.h"
#import "FPLargeObject.h"



@implementation FPCreateLargeObjectOperation


#pragma mark Properties
@synthesize data = _data;


#pragma mark Init / Dealloc
- (id)init
{
		self = [super init];
	if (self){
		_data = nil;
	}
	return self;
}

- (id)initWithConnection:(FPConnection *)theConnection
				withData:(NSData *)theData
		  withIdentifier:(NSString *)identifier
		withNotification:(NSString *)notification
			withMetadata:(NSDictionary *)metadata
			withPriority:(FPRequestQueuePriority)priority
				withLock:(NSLock *)theLock
{
		self = [super init];
	if (self){
		self.data = theData;
		self.identifierString = identifier;
		self.notificationString = notification;
		self.connection = theConnection;
		self.metadataDictionary = metadata;
		self.lock = theLock;
		[self setQueuePriority:priority];
	}
	return self;
}

- (void)dealloc
{
	[_data release];
	[super dealloc];
}


#pragma mark NSOperation Implementation
- (void)main
{
	NSAutoreleasePool	*pool = [NSAutoreleasePool new];
	
	@try {
		Oid 				oidValue = InvalidOid;
		NSInteger			fd = 0;
		NSInteger			returnCode = 0;
		NSString			*reason = nil;
		FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:self.connection
																	   withLock:self.lock];
		//Is Cancelled
		if ([self isCancelled]) 
		{
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Check connection
		if (![self.connection checkThisConnection]) 
		{
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPPSQLConnectionFailed];
			return;
		}
		
		//Is Cancelled
		if ([self isCancelled]) 
		{
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPPSQLOperationCancelled];
			return;
		}
		
		//Begin Transaction
		if ((reason = [largeObject beginLargeObject])) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, reason);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:reason];
			[largeObject release];
			return;
		}		
		
		//Create oid
		[self.lock lock];
		oidValue = lo_creat(self.connection.connection, INV_READ|INV_WRITE);
		[self.lock unlock];
		
		if (oidValue == InvalidOid)
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationInvalidOid);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPCreateLargeObjectOperationInvalidOid];
			
			//End Transaction
			[largeObject endLargeObject];
			[largeObject release];
			return;
		}		
		
		//Open
		[self.lock lock];
		fd = lo_open(self.connection.connection, oidValue, INV_READ|INV_WRITE);
		[self.lock unlock];
		
		if (fd < 0) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationBadFd);
#endif
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPCreateLargeObjectOperationBadFd];
			
			//End Transaction
			[largeObject endLargeObject];
			[largeObject release];
			return;
		}
		
#ifdef PG_DEBUG
		NSLog(@"%s: fd:%ld\t[data bytes]:%s\t[data length]:%lu", __FILE__, fd, [_data bytes], [_data length]);
#endif	
		
		//Write
		[self.lock lock];
		returnCode = lo_write(self.connection.connection, fd, [_data bytes], (size_t)[_data length]);
		[self.lock unlock];
		
		if (returnCode < 0) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationWriteError);
#endif		
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPCreateLargeObjectOperationWriteError];
			
			//End Transaction
			[largeObject endLargeObject];
			[largeObject release];
			return;
		}
		
		//Close
		[self.lock lock];
		returnCode = lo_close(self.connection.connection, fd);
		[self.lock unlock];
		
		if (returnCode < 0) 
		{
#ifdef PG_DEBUG
			NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationCloseError);
#endif		
			
			[self finishOperationWithRequest:[NSString stringWithFormat:@"%d", oidValue]
								   withError:FPCreateLargeObjectOperationWriteError];
			
			//End Transaction
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
			
			[self finishOperationWithRequest:reason
								   withError:FPCreateLargeObjectOperationWriteError];
			[reason release];
			[largeObject release];
			return;
		}		
		
		//Send the results
		[self finishOperationWithRequest:[NSNumber numberWithInt:oidValue]
							   withError:nil
							  withResult:nil];
		[largeObject release];
		
	} 
	@catch (NSException *e) 
	{
#if defined LOG || defined DEBUG
		NSLog(@"%s:%@%@", __FILE__, [e name], [e reason]);
#endif		
		
		@throw;
		
	} 
	@finally 
	{				
		[pool release];	
	}	
}

@end
