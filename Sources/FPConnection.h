//
//  FPConnection.h
//  PostgreSQL.framework
//
//  Created by Flying Pig on 8/2/06.
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



@interface  FPConnection : NSObject {
	
@private
	PGconn							*_connection;
	NSLock							*_lock;
	NSString						*_hostString;
	NSString						*_loginString;
	NSString						*_passwordString;	
	NSString						*_dbString;
	NSUInteger						_portInteger;
	BOOL							_sslSupportBool;
}


//Properties
@property(readonly) PGconn			*connection;
@property(retain) NSLock			*lock;
@property(retain, setter=setHostString:, getter=hostString) NSString			*hostString;
@property(retain) NSString			*loginString;
@property(retain) NSString			*passwordString;
@property(retain) NSString			*dbString;
@property NSUInteger				portInteger;
@property BOOL						sslSupportBool;


//Init
- (id)initWithHost:(NSString *)host
		 withLogin:(NSString *)login
	  withPassword:(NSString *)password
			withDb:(NSString *)db
		  withPort:(NSUInteger)port
		   withSSL:(BOOL)sslSupport
		  withLock:(NSLock *)theLock;

//Connection
- (BOOL)connect;
- (void)closeConnection;
- (BOOL)reconnect;
- (void)reset;
- (ConnStatusType)status;
- (BOOL)cancel;
      
//Check Connections Status
- (BOOL)checkThisConnection;
- (NSString *)checkThisConnectionWithFeedback;

@end
