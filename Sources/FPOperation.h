//
//  FPOperation.h
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

#import <Foundation/Foundation.h>

#import <FPPostgreSQL/FPPSQLIdentifiers.h>


@class FPConnection;

@interface FPOperation : NSOperation
{
	
	NSThread						*_startingThread;
@private
	NSLock							*_lock;
	FPConnection					*_connection;
	
	//Request ivars
	NSString						*_identifierString;
	NSString						*_notificationString;
	NSDictionary					*_metadataDictionary;
}


//Properties
@property (assign) FPPSQL			*pgsqlCore;
@property(retain) FPConnection		*connection;
@property(retain) NSLock			*lock;
@property(retain) NSString			*identifierString;
@property(retain) NSString			*notificationString;
@property(retain) NSDictionary		*metadataDictionary;


//Finish Operation
- (void)finishOperationWithRequest:(id)request
						 withError:(NSString *)error;
- (void)finishOperationWithRequest:(id)request
						 withError:(NSString *)error
						withResult:(id)result;
- (void)postNotifWithObjectArray:(NSArray *)objArray;

@end
