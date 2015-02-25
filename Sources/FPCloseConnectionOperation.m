//
//  FPCloseConnectionOperation.m
//  FPPostgreSQL
//
//  Created by Flying Pig on 7/21/09.
//  Copyright © 2009 Flying Pig. All rights reserved.
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

#import "FPCloseConnectionOperation.h"

//Request Identifier
#define FPCloseConnectionOperationRequest										@"closeConnect"
//Errors
#define FPCloseConnectionOperationErrorRequest									@"Close Connection"	


@implementation FPCloseConnectionOperation


#pragma mark NSOperation Implementation
- (void)main
{
	NSAutoreleasePool		*pool = [NSAutoreleasePool new];
	
	@try 
	{
	
		NSMutableDictionary		*resultsMutableDic = nil;
		
#ifdef PG_DEBUG
		NSLog(@"%s: requestString:%@", __FILE__, @"Connection");
#endif	
		
		//Is Cancelled
		if ([self isCancelled]) 
		{
			[self finishOperationWithRequest:FPCloseConnectionOperationErrorRequest
								   withError:FPPSQLOperationCancelled];
			return;
		}
				
		//Trying to etablish the connection to the server
		[self.connection closeConnection];		
		
		//Prepare the result
		resultsMutableDic = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], FPPSQLResults,
							 nil];
		[resultsMutableDic setObject:FPCloseConnectionOperationRequest forKey:self.identifierString];
		
		//Return the metadata too if we have it
		if (self.metadataDictionary)
			[resultsMutableDic setObject:self.metadataDictionary forKey:FPPSQLResultsMetadata];	
		
		FPPSQLResult *result = [[FPPSQLResult alloc] initWithLegacyDictionary:resultsMutableDic];
		[resultsMutableDic release];
		
		//		result.request = request;
		result.requestIdentifier = self.identifierString;
		//Send the result with Notification
#ifdef __FPPG_RETURNS_IN_BG
		[self performSelectorInBackground:@selector(postNotifWithObjectArray:) withObject:@[self.notificationString, result]];
#else
		[self performSelectorOnMainThread:@selector(postNotifWithObjectArray:) withObject:@[self.notificationString, result] waitUntilDone:NO];
#endif
		
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
