//
//  FPPSQLResult.h
//  FPPostgreSQL
//
//  Created by Arnaud Thiercelin on 6/27/12.
//
//

#import <Foundation/Foundation.h>

@interface FPPSQLResult : NSObject <NSCoding>

@property (retain) NSString			*request;
@property (retain) NSString			*requestIdentifier;
@property (retain) NSString			*error;
@property (retain) NSArray			*columnHeaders;
@property (retain) NSArray			*columnTypes; // list in order of oids
@property (retain) NSArray			*arrayResults;
@property (retain) NSNumber			*numberResults;
@property (retain) NSDictionary		*metadata;

@property (readonly, getter=legacyDict) NSDictionary		*legacyDict; // Generated with Stored data.

- (id)initWithLegacyDictionary:(NSDictionary *)legacyDictionary;

- (id)objectForKey:(NSString *)key;

- (NSDictionary *)legacyDict;

- (void)updateObjectTypesInResults;

@end
