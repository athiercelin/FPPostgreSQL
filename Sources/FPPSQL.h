//
//  FPPSQL.h
//  PostgreSQL
//
//  Created by Flying Pig on 23/05/06.
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

#include <string.h>
#import <FPPostgreSQL/libpq-fe.h>
#import <FPPostgreSQL/FPPSQLIdentifiers.h>
#import <FPPostgreSQL/FPPSQLResult.h>

#define FPPSQLTargetSelectorDefaultNotif		@"FPPSQLTargetSelectorDefaultNotif"

@class FPConnection;
@class FPOperation;

@interface FPPSQL : NSObject {
	
@private
	
	//Threads management
	NSLock									*_lock;
	NSOperationQueue						*_operationQueue;
	
	//Database Connection
	FPConnection							*_connection;
}

//Properties
@property(readonly) FPConnection			*connection;
@property(readonly) NSLock					*lock;
@property(readonly) NSOperationQueue		*operationQueue;

@property (retain) NSMutableArray			*targetSelectorRequests;

//init
- (id)initWithHost:(NSString *)anHost
		 withLogin:(NSString *)aLogin
	  withPassword:(NSString *)aPassword
			withDb:(NSString *)aDb
		  withPort:(NSUInteger)aPort
		   withSSL:(BOOL)sslSupport;

//Getters
- (NSString *)host;
- (NSString *)login;
- (NSString *)password;
- (NSString *)db;
- (NSUInteger)port;
- (BOOL)sslSupport;

//Setters
- (void)setHost:(NSString *)newHost;
- (void)setLogin:(NSString *)newLogin;
- (void)setPassword:(NSString *)newPassword;
- (void)setDb:(NSString *)newDb;
- (void)setPort:(NSUInteger)newPort;
- (void)setSslSupport:(BOOL)newSslSupport;
- (void)setDependencies:(NSArray *)dependenciesArray
		   forOperation:(FPOperation *)operation;

//Connexion Asynchronous
- (void)connectWithIdentifier:(NSString *)identifier 
			 withNotification:(NSString *)notification
			 withDependencies:(NSArray *)dependencies
				 withMetadata:(NSDictionary *)metadata
				 withPriority:(FPRequestQueuePriority)priority;
- (void)reconnectWithIdentifier:(NSString *)identifier 
			   withNotification:(NSString *)notification
			   withDependencies:(NSArray *)dependencies
				   withMetadata:(NSDictionary *)metadata
				   withPriority:(FPRequestQueuePriority)priority;
- (void)closeConnectionWithIdentifier:(NSString *)identifier 
					 withNotification:(NSString *)notification
					 withDependencies:(NSArray *)dependencies
						 withMetadata:(NSDictionary *)metadata
						 withPriority:(FPRequestQueuePriority)priority;


#pragma mark Connexion Synchronous
- (BOOL)connect;
- (void)closeConnection;
- (BOOL)reconnect;

#pragma mark Error Management
- (NSString *)latestPQErrorMessage;


#pragma mark Asynchronous Request methods
- (void)execRequest:(NSString *)request 
	 withIdentifier:(NSString *)identifier 
   withNotification:(NSString *)notification
   withDependencies:(NSArray *)dependencies
       withMetadata:(NSDictionary *)metadata
	   withPriority:(FPRequestQueuePriority)priority;

- (void)targetSelectorCatcher:(FPPSQLResult *)reqResult;

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
   withDependencies:(NSArray *)dependencies
	   withMetadata:(NSDictionary *)metadata
	   withPriority:(FPRequestQueuePriority)priority;
/*
- (void)execRequest:(NSString *)request 
	 withIdentifier:(NSString *)identifier 
	   withSelector:(SEL)action
		 withTarget:(id)target
   withDependencies:(NSArray *)dependencies
       withMetadata:(NSDictionary *)metadata
	   withPriority:(FPRequestQueuePriority)priority;
*/

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
	   withMetadata:(NSDictionary *)metadata;

//Synchronous Request methods
- (FPPSQLResult *)execRequest:(NSString *)request;
- (FPPSQLResult *)execRequest:(NSString *)request withRequestIdentifier:(NSString *)requestIdentifier;


//Asynchronous Cancel requests
- (BOOL)cancelWithIdentifier:(NSString *)identifier;

//Synchronous Cancel requests
- (BOOL)cancelRequest;


//Asynchronous Large Objects methods
- (void)createLargeObjectWithData:(NSData *)data
				   withIdentifier:(NSString *)identifier
				 withNotification:(NSString *)notification
				 withDependencies:(NSArray *)dependencies
					 withMetadata:(NSDictionary *)metadata
					 withPriority:(FPRequestQueuePriority)priority;
- (void)selectLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority;
- (void)updateLargeObjectWithOid:(Oid)oidValue
						withData:(NSData *)data
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority;
- (void)removeLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority;


//Synchronous Large Objects methods
- (Oid)createLargeObjectWithData:(NSData *)data;
- (NSData *)selectLargeObjectWithOid:(Oid)oidValue;
- (BOOL)updateLargeObjectWithOid:(Oid)oidValue
						withData:(NSData *)data;
- (BOOL)removeLargeObjectWithOid:(Oid)oidValue;

@end
