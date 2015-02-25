//
//  FPPSQL.m
//  PostgreSQL
//
//  Created by Flying Pig on 23/05/06.
//  Copyright © 2008 Flying Pig. All rights reserved.
//
//  Redistribution and use in binary form, without modification, are permitted provided that the following conditions are met:
//  ¥	Redistributions in binary form must not be under any other license or conditions other than the ones described in this notice.
//  ¥	Sell licenses for this software is strictly forbidden.
//  ¥	Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer
//  in the documentation and/or other materials provided with the distribution.
//  ¥	Neither the name of the Flying Pig SARL nor the names of any Flying Pig products using this software, including Edouard(R),
//  nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
//  BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
//  OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "FPPSQL.h"

#import "libpq-fs.h"
#import "FPConnection.h"
#import "FPRequest.h"
#import "FPRequestOperation.h"
#import "FPConnectionOperation.h"
#import "FPReconnectionOperation.h"
#import "FPCloseConnectionOperation.h"
#import "FPCreateLargeObjectOperation.h"
#import "FPSelectLargeObjectOperation.h"
#import "FPUpdateLargeObjectOperation.h"
#import "FPDeleteLargeObjectOperation.h"
#import "FPLargeObject.h"

//Exceptions
//#define LOSELECTOPENEXCEPTION										@"FPPGSQL.Framework lo_openException"
//#define LOSELECTOPENEXCEPTIONREASON								@"Opening a large object failed, is the connection up and running? is you lo_oid correct?"
//#define LOSELECTBEGINEXCEPTION									@"FPPGSQL.Framework LO select 'Begin' exception"
//#define LOSELECTENDEXCEPTION										@"FPPGSQL.Framework LO select 'End' exception"
//#define LOSELECTCLOSEEXCEPTION									@"FPPSQL.Framework lo_closeException"
//#define LOSELECTCLOSEEXCEPTIONREASON								@"Closing the fd failed, check the connection status..."


//OperationQueue's Name
#define FPPSQLOperationQueueName									@"FPPostgreSQL"



@interface FPPSQL (Private)

//Getters
- (FPOperation *)operationWithIdentifier:(NSString *)identifier;

@end


@implementation FPPSQL (Private)


#pragma mark Getters
- (FPOperation *)operationWithIdentifier:(NSString *)identifier
{
	for (FPOperation *operation in [_operationQueue operations])
		if ([operation.identifierString isEqualToString:identifier])
			return operation;
	return nil;
}

@end



@implementation FPPSQL


#pragma mark Properties
@synthesize connection = _connection;
@synthesize lock = _lock;
@synthesize operationQueue = _operationQueue;


#pragma mark Init/Dealloc
- (id)init
{
	if (self == [super init])
	{
		_lock = [NSLock new];
		_operationQueue = [NSOperationQueue new];
		//[_operationQueue setName:FPPSQLOperationQueueName];
		_connection = [FPConnection new];
		_connection.lock = _lock;
		
		self.targetSelectorRequests = [NSMutableArray new];
	}
	return self;
}

- (id)initWithHost:(NSString *)anHost
		 withLogin:(NSString *)aLogin
	  withPassword:(NSString *)aPassword
			withDb:(NSString *)aDb
		  withPort:(NSUInteger)aPort
		   withSSL:(BOOL)sslSupport
{
	if (self == [self init])
	{
		[_connection release];
		_connection = [[FPConnection alloc] initWithHost:anHost
											   withLogin:aLogin 
											withPassword:aPassword 
												  withDb:aDb
												withPort:aPort
												 withSSL:sslSupport
												withLock:self.lock];
	}
	return self;
}

- (void)dealloc
{	
	[_operationQueue cancelAllOperations];
	[_operationQueue release];
	[_connection release];	
	[_lock release];
	self.targetSelectorRequests = nil;
	[super dealloc];
}


#pragma mark Getters
- (NSString *)host
{
	return _connection.hostString;
}

- (NSString *)login
{
	return _connection.loginString;
}

- (NSString *)password
{
	return _connection.passwordString;
}

- (NSString *)db
{
	return _connection.dbString;
}

- (NSUInteger)port
{
	return _connection.portInteger;
}

- (BOOL)sslSupport
{
	return _connection.sslSupportBool;
}


#pragma mark Setters
- (void)setHost:(NSString *)newHost
{
	_connection.hostString = newHost;
}

- (void)setLogin:(NSString *)newLogin
{
	_connection.loginString = newLogin;
}

- (void)setPassword:(NSString *)newPassword
{
	_connection.passwordString = newPassword;
}

- (void)setDb:(NSString *)newDb
{
	_connection.dbString = newDb;
}

- (void)setPort:(NSUInteger)newPort
{
	_connection.portInteger = newPort;
}

- (void)setSslSupport:(BOOL)newSslSupport
{
	_connection.sslSupportBool = newSslSupport;
}

- (void)setDependencies:(NSArray *)dependenciesArray
		   forOperation:(FPOperation *)operation
{
	for (NSString *identifierString in dependenciesArray) {
		
		FPOperation		*dependedOperation = nil;
		
		if ((dependedOperation = [self operationWithIdentifier:identifierString]))
			[operation addDependency:dependedOperation];
	}
}


#pragma mark Asynchronous DataBase connection
- (void)connectWithIdentifier:(NSString *)identifier 
			 withNotification:(NSString *)notification
			 withDependencies:(NSArray *)dependencies
				 withMetadata:(NSDictionary *)metadata
				 withPriority:(FPRequestQueuePriority)priority
{
	FPConnectionOperation	*operation = [[FPConnectionOperation alloc] initWithConnection:_connection
																		  withIdentifier:identifier
																		withNotification:notification
																			withMetadata:metadata
																			withPriority:priority
																				withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
}

- (void)reconnectWithIdentifier:(NSString *)identifier 
			   withNotification:(NSString *)notification
			   withDependencies:(NSArray *)dependencies
				   withMetadata:(NSDictionary *)metadata
				   withPriority:(FPRequestQueuePriority)priority
{
	FPReconnectionOperation	*operation = [[FPReconnectionOperation alloc] initWithConnection:_connection
																			  withIdentifier:identifier
																			withNotification:notification
																				withMetadata:metadata
																				withPriority:priority
																					withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
}

- (void)closeConnectionWithIdentifier:(NSString *)identifier 
					 withNotification:(NSString *)notification
					 withDependencies:(NSArray *)dependencies
						 withMetadata:(NSDictionary *)metadata
						 withPriority:(FPRequestQueuePriority)priority
{
	FPCloseConnectionOperation	*operation = [[FPCloseConnectionOperation alloc] initWithConnection:_connection
																					withIdentifier:identifier
																				  withNotification:notification
																					  withMetadata:metadata
																					  withPriority:priority
																						  withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
}


#pragma mark Synchronous DataBase connection
- (BOOL)connect
{
	return [_connection connect];
}

- (void)closeConnection
{
	[_operationQueue cancelAllOperations];
	[_connection closeConnection];
}

- (BOOL)reconnect
{
	return [_connection reconnect];
}

#pragma mark Error Management

- (NSString *)latestPQErrorMessage
{
	return [NSString stringWithFormat:@"%s", PQerrorMessage(_connection.connection)];
}

#pragma mark Asynchronous Request methods
- (void)execRequest:(NSString *)request 
	 withIdentifier:(NSString *)identifier 
   withNotification:(NSString *)notification
   withDependencies:(NSArray *)dependencies
       withMetadata:(NSDictionary *)metadata
	   withPriority:(FPRequestQueuePriority)priority
{
	FPRequestOperation	*operation = [[FPRequestOperation alloc] initWithConnection:_connection
																	   withRequest:request
																	withIdentifier:identifier
																  withNotification:notification
																	  withMetadata:metadata
																	  withPriority:priority
																		  withLock:self.lock];

	operation.pgsqlCore = self;
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];
}

- (void)targetSelectorCatcher:(FPPSQLResult *)reqResult
{
	FPPSQLResult *obj = reqResult;
	BOOL shouldRemoveItem = NO;
	
	[_lock lock];
	NSUInteger index;
	
	for (index = 0; index < [self.targetSelectorRequests count]; index++)
	{
		NSDictionary *item = [self.targetSelectorRequests objectAtIndex:index];
		NSString *reqId = [item objectForKey:@"requestIdentifier"];
		id target = [item objectForKey:@"target"];
		SEL selector = [[item objectForKey:@"selector"] pointerValue];
		
		if ([obj objectForKey:reqId])
		{
			[target performSelector:selector withObject:obj];
			shouldRemoveItem = YES;
			break;
		}
	}
	if (shouldRemoveItem)
		[self.targetSelectorRequests removeObjectAtIndex:index];
	[_lock unlock];
}

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
   withDependencies:(NSArray *)dependencies
	   withMetadata:(NSDictionary *)metadata
	   withPriority:(FPRequestQueuePriority)priority
{
	// add to array.
	NSDictionary *newTargetSelItem = @{@"requestIdentifier" : identifier,
	@"target" : target,
	@"selector" : [NSValue valueWithPointer:selector]};

	[self.targetSelectorRequests addObject:newTargetSelItem];
	[self execRequest:request
	   withIdentifier:identifier
	 withNotification:FPPSQLTargetSelectorDefaultNotif
	 withDependencies:dependencies
		 withMetadata:metadata
		 withPriority:priority];
}

/*
 - (void)execRequest:(NSString *)request 
 withIdentifier:(NSString *)identifier 
 withSelector:(SEL)action
 withTarget:(id)target
 withDependencies:(NSArray *)dependencies
 withMetadata:(NSDictionary *)metadata
 withPriority:(FPRequestQueuePriority)priority
 {
 FPRequestOperation			*operation = [[FPRequestOperation alloc] initWithConnection:_connection
 withRequest:request
 withIdentifier:identifier
 withNotification:notification
 withMetadata:metadata
 withPriority:priority
 withLock:self.lock];
 
 [self setDependencies:dependencies
 forOperation:operation];
 [_operationQueue addOperation:operation];
 [operation release];
 
 }
 */

- (void)execRequest:(NSString *)request
	 withIdentifier:(NSString *)identifier
		 withTarget:(id)target
	   withSelector:(SEL)selector
	   withMetadata:(NSDictionary *)metadata
{
	[self execRequest:request
	   withIdentifier:identifier
		   withTarget:target
		 withSelector:selector
	 withDependencies:nil
		 withMetadata:metadata
		 withPriority:FPRequestQueuePriorityNormal];
}

#pragma mark Synchronous Request methods
- (FPPSQLResult *)execRequest:(NSString *)request
{
	return [self execRequest:request withRequestIdentifier:@"FPPostgreSQLNoRequestIdentifier"];
}

- (FPPSQLResult *)execRequest:(NSString *)request withRequestIdentifier:(NSString *)requestIdentifier
{
	PGresult			*pgresult;
	NSDictionary		*results = nil;
	
#ifdef PG_DEBUG
	NSLog(@"%s: request:%@", __FILE__, request);
#endif
	FPPSQLResult *newResult = [FPPSQLResult new];
		
	//Check connection
	if (![_connection checkThisConnection])
	{
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__,  FPPSQLConnectionFailed);
#endif
		
		newResult.request = request;
		newResult.requestIdentifier = requestIdentifier;
		newResult.error = FPPSQLConnectionFailed;

		return newResult;
	}
	
	//Exec the request
	[self.lock lock];
	pgresult = PQexec(_connection.connection, [request cStringUsingEncoding:NSUTF8StringEncoding]);	
	[self.lock unlock];
	
	if (!pgresult)
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPPSQLExecutionFailed);
#endif
		
		newResult.request = request;
		newResult.requestIdentifier = requestIdentifier;
		newResult.error = FPPSQLConnectionFailed;
		
		return newResult;
	}
	
	//Get the result from an "UPDATE, DELETE OR INSERT" request
	if ((results = [FPRequest getResultsFromEditRequestWithPGResult:pgresult])) 
	{
		PQclear(pgresult);
		
		//ignore warning, private api call.
		newResult.request = request;
		newResult.requestIdentifier = requestIdentifier;
		newResult.error = [results objectForKey:FPPSQLResultsError];
		newResult.numberResults = [results objectForKey:FPPSQLResults];
		
		[results release];
		return newResult;
	}
	
	//Get the result from a "SELECT" request
	results = [FPRequest getResultsFromSelectRequestWithPGResult:pgresult];
	
	newResult.request = request;
	newResult.requestIdentifier = requestIdentifier;
	newResult.error = [results objectForKey:FPPSQLResultsError];
	newResult.arrayResults = [results objectForKey:FPPSQLResults];
	newResult.columnHeaders = [results objectForKey:FPPSQLResultsColumnHeaders];
	
	[results release];	
	PQclear(pgresult);
	return newResult; 
}


#pragma mark Asynchronous Cancel requests
- (BOOL)cancelWithIdentifier:(NSString *)identifier
{
	FPOperation		*operation = [self operationWithIdentifier:identifier];
	
	if (operation) {
		[operation cancel];	
		return YES;
	}
	return NO;
}


#pragma mark Synchronous Cancel requests
- (BOOL)cancelRequest
{
	return [_connection cancel];
}


#pragma mark Asynchronous Large Objects methods
- (void)createLargeObjectWithData:(NSData *)data
				   withIdentifier:(NSString *)identifier
				 withNotification:(NSString *)notification
				 withDependencies:(NSArray *)dependencies
					 withMetadata:(NSDictionary *)metadata
					 withPriority:(FPRequestQueuePriority)priority
{
	FPCreateLargeObjectOperation		*operation = [[FPCreateLargeObjectOperation alloc] initWithConnection:_connection
																							   withData:data
																						 withIdentifier:identifier
																					   withNotification:notification
																						   withMetadata:metadata
																						   withPriority:priority
																							   withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
}

- (void)selectLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority
{
	FPSelectLargeObjectOperation		*operation = [[FPSelectLargeObjectOperation alloc] initWithConnection:_connection
																								withOid:oidValue
																						 withIdentifier:identifier 
																					   withNotification:notification
																						   withMetadata:metadata
																						   withPriority:priority
																							   withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
	
}

- (void)updateLargeObjectWithOid:(Oid)oidValue
						withData:(NSData *)data
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority
{
	FPUpdateLargeObjectOperation		*operation = [[FPUpdateLargeObjectOperation alloc] initWithConnection:_connection 
																								withOid:oidValue 
																							   withData:data 
																						 withIdentifier:identifier 
																					   withNotification:notification
																						   withMetadata:metadata
																						   withPriority:priority
																							   withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];
	[_operationQueue addOperation:operation];
	[operation release];	
}

- (void)removeLargeObjectWithOid:(Oid)oidValue
				  withIdentifier:(NSString *)identifier
				withNotification:(NSString *)notification
				withDependencies:(NSArray *)dependencies
					withMetadata:(NSDictionary *)metadata
					withPriority:(FPRequestQueuePriority)priority
{
	FPDeleteLargeObjectOperation		*operation = [[FPDeleteLargeObjectOperation alloc] initWithConnection:_connection 
																								withOid:oidValue
																						 withIdentifier:identifier 
																					   withNotification:notification
																						   withMetadata:metadata
																						   withPriority:priority
																							   withLock:self.lock];
	
	if (dependencies)
		[self setDependencies:dependencies
				 forOperation:operation];	
	[_operationQueue addOperation:operation];
	[operation release];	
}


#pragma mark Synchronous Large Objects methods
- (Oid)createLargeObjectWithData:(NSData *)data
{
	Oid 				oidValue = InvalidOid;
	NSInteger			fd = 0;
	NSInteger			returnCode = 0;
	NSString			*reason = nil;
	FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:_connection
																   withLock:self.lock];
	
	if (![_connection checkThisConnection]) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPPSQLConnectionFailed);
#endif
		
		[largeObject release];
		return InvalidOid;
	}
	
	//Begin Transaction
	if ((reason = [largeObject beginLargeObject])) 
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return InvalidOid;
	}
	
	//Create oid
	[self.lock lock];
	oidValue = lo_creat(_connection.connection, INV_READ|INV_WRITE);
	[self.lock unlock];
	
	if (oidValue == InvalidOid) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationInvalidOid);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return InvalidOid;
	}
	
	//Open
	[self.lock lock];
	fd = lo_open(_connection.connection, oidValue, INV_READ|INV_WRITE);
	[self.lock unlock];
	
	if (fd < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationBadFd);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return InvalidOid;
	}
	
#ifdef PG_DEBUG
	NSLog(@"%s: fd:%ld\t[data bytes]:%s\t[data length]:%lu", __FILE__, fd, [data bytes], [data length]);
#endif	
	
	//Write
	[self.lock lock];
	returnCode = lo_write(_connection.connection, fd, [data bytes], (size_t)[data length]);
	[self.lock unlock];
	
	if (returnCode < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationWriteError);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return InvalidOid;
	}
	
	// Close
	[self.lock lock];
	returnCode = lo_close(_connection.connection, fd);
	[self.lock unlock];
	
	if (returnCode < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPCreateLargeObjectOperationCloseError);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return InvalidOid;
	}
	
	//End Transaction
	if ((reason = [largeObject endLargeObject])) 
	{
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return InvalidOid;
	}		
	
	
	return oidValue;
}

- (NSData *)selectLargeObjectWithOid:(Oid)oidValue
{
	NSInteger			fd = 0;
	NSInteger			closeStatus = 0;
	NSString			*reason = nil;
	FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:_connection
																   withLock:self.lock];
	NSData				*data = nil;
	
	if (![_connection checkThisConnection]) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPPSQLConnectionFailed);
#endif
		
		[largeObject release];
		return nil;
	}
	
	//Begin Transaction
	if ((reason = [largeObject beginLargeObject])) 
	{
		//reason
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return nil;
	}		
	
	//Open
	[self.lock lock];
	fd = lo_open(_connection.connection, oidValue, INV_READ|INV_WRITE);	
	[self.lock unlock];	
	
	if (fd < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationBadFd);
#endif
		
		//End Transaction
		[largeObject endLargeObject];
		[largeObject release];
		return nil;
		
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
	if ((data = [largeObject readLargeObjectWithFd:fd]) == nil) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationDataError);
#endif
		
		
		//End Transaction
		[largeObject endLargeObject];
		[largeObject release];
		return nil;		
	}
	
	
	//Close
	[self.lock lock];
	closeStatus = lo_close(_connection.connection, fd);
	[self.lock unlock];
	
	if (closeStatus < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPSelectLargeObjectOperationCloseError);
#endif
		
		[data release];
		
		//End Transaction
		[largeObject endLargeObject];
		[largeObject release];
		return nil;
		
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
	if ((reason = [largeObject endLargeObject])) 
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[data release];
		[largeObject release];
		return nil;
	}		
	
	//Send the results
	[largeObject release];
	return data;
}

- (BOOL)updateLargeObjectWithOid:(Oid)oidValue withData:(NSData *)data
{
	NSInteger					fd = 0;
	NSInteger					returnCode = 0;
	NSString			*reason = nil;
	FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:_connection
																   withLock:self.lock];
	
	if (![_connection checkThisConnection]) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPPSQLConnectionFailed);
#endif
		
		[largeObject release];
		return NO;
	}
	
	//Begin Transaction
	if ((reason = [largeObject beginLargeObject]))
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return NO;
	}
	
	//Open
	[self.lock lock];
	fd = lo_open(_connection.connection, oidValue, INV_READ|INV_WRITE);
	[self.lock unlock];
	
	if (fd < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPUpdateLargeObjectOperationBadFd);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return NO;
	}
	
	//Write
	[self.lock lock];
	returnCode = lo_write(_connection.connection, fd, [data bytes], (size_t)[data length]);
	[self.lock unlock];
	
	if (returnCode < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPUpdateLargeObjectOperationWriteError);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return NO;
	}
	
	//Close
	[self.lock lock];
	returnCode = lo_close(_connection.connection, fd);
	[self.lock unlock];
	
	if (returnCode < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPUpdateLargeObjectOperationCloseError);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return NO;
	}
	
	//End Transaction
	if ((reason = [largeObject endLargeObject]))
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return NO;
	}
	
	[largeObject release];
	return YES;
}

- (BOOL)removeLargeObjectWithOid:(Oid)oidValue
{
	NSInteger					unlinkReturnCode = 0;
	NSString			*reason = nil;
	FPLargeObject		*largeObject = [[FPLargeObject alloc] initWithConnection:_connection
																   withLock:self.lock];
	
	if (![_connection checkThisConnection]) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPPSQLConnectionFailed);
#endif
		
		[largeObject release];
		return NO;
	}
	
	//Begin Transaction
	if ((reason = [largeObject beginLargeObject])) 
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return NO;
	}
	
	[self.lock lock];
	unlinkReturnCode = lo_unlink(_connection.connection, oidValue);
	[self.lock unlock];
	
	if (unlinkReturnCode < 0) {
		
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, FPDeleteLargeObjectOperationDeleteError);
#endif
		
		[largeObject endLargeObject];
		[largeObject release];
		return NO;
		
	}
	
	//End Transaction
	if ((reason = [largeObject endLargeObject])) 
	{
#ifdef PG_DEBUG
		NSLog(@"%s:%@", __FILE__, reason);
#endif
		
		[largeObject release];
		return NO;
	}
	
	[largeObject release];
	return YES;
}

@end

