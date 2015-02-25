//
//  FPPSQLResult.m
//  FPPostgreSQL
//
//  Created by Arnaud Thiercelin on 6/27/12.
//
//

#import "FPPSQLResult.h"

#import "FPPSQLIdentifiers.h"


@implementation FPPSQLResult

- (id)init
{
    self = [super init];
    if (self)
	{
		self.request = nil;
		self.requestIdentifier = nil;
		self.error = nil;
		self.columnHeaders = nil;
		self.columnTypes = nil;
		self.arrayResults = nil;
		self.numberResults = nil;
		self.metadata = nil;
    }
    return self;
}


- (id)initWithLegacyDictionary:(NSDictionary *)legacyDictionary
{
    self = [self init];
    if (self)
	{
		self.request = nil; //not supported if only legacy dict is provided
		self.requestIdentifier = nil;
		self.error = [legacyDictionary objectForKey:FPPSQLResultsError];
		self.columnHeaders = [legacyDictionary objectForKey:FPPSQLResultsColumnHeaders];
		self.columnTypes = [legacyDictionary objectForKey:FPPSQLResultsColumnTypes];
		
		id results = [legacyDictionary objectForKey:FPPSQLResults];

		if ([[results class] isSubclassOfClass:[NSArray class]])
			self.arrayResults = results;
		else
			self.numberResults = results;
		self.metadata = [legacyDictionary objectForKey:FPPSQLResultsMetadata];
    }
    return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
    self.request = nil;
	self.requestIdentifier = nil;
	self.error = nil;
	self.columnHeaders = nil;
	self.columnTypes = nil;
	self.arrayResults = nil;
	self.numberResults = nil;
	self.metadata = nil;
    [super dealloc];
}
#endif

- (NSString *)description
{
	return [NSString stringWithFormat:@" \n\
			FPPSQLResult - %p\n\
			------------\n\
			Request: %@\n\
			Request Id: %@\n\
			Error: %@ \n\
			ColumnHeaders: %@\n\
			ArrayResults: %@\n\
			NumberResults: %@\n\
			Metadata: %@\n\
			LegacyDict: %p\n\
			LegacyDictData:%@ \n\
			",
			self,
			self.request,
			self.requestIdentifier,
			self.error,
			self.columnHeaders,
			self.arrayResults,
			self.numberResults,
			self.metadata,
			self.legacyDict,
			self.legacyDict
			];
}

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.request forKey:@"request"];
	[aCoder encodeObject:self.requestIdentifier forKey:@"requestIdentifier"];
	[aCoder encodeObject:self.error forKey:@"error"];
	[aCoder encodeObject:self.columnHeaders forKey:@"columnHeaders"];
	[aCoder encodeObject:self.arrayResults forKey:@"arrayResults"];
	[aCoder encodeObject:self.numberResults forKey:@"numberResults"];
	[aCoder encodeObject:self.metadata forKey:@"metadata"];
	
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [self init];
	
	if (self)
	{
		self.request = [aDecoder decodeObjectForKey:@"request"];
		self.requestIdentifier = [aDecoder decodeObjectForKey:@"requestIdentifier"];
		self.error = [aDecoder decodeObjectForKey:@"error"];
		self.columnHeaders = [aDecoder decodeObjectForKey:@"columnHeaders"];
		self.arrayResults = [aDecoder decodeObjectForKey:@"arrayResults"];
		self.numberResults = [aDecoder decodeObjectForKey:@"numberResults"];
		self.metadata = [aDecoder decodeObjectForKey:@"metadata"];
	}
	return self;
}

- (id)objectForKey:(NSString *)key
{
	return [self.legacyDict objectForKey:key];
}

- (NSDictionary *)legacyDict
{
	NSMutableDictionary *tempDict = [NSMutableDictionary new];
	
	if (self.requestIdentifier && self.request)
		[tempDict setObject:self.request forKey:self.requestIdentifier];
	
	if (self.error)
		[tempDict setObject:self.error forKey:FPPSQLResultsError];
	if (self.columnHeaders)
		[tempDict setObject:self.columnHeaders forKey:FPPSQLResultsColumnHeaders];
	
	if (self.arrayResults)
		[tempDict setObject:self.arrayResults forKey:FPPSQLResults];
	else if (self.numberResults)
		[tempDict setObject:self.numberResults forKey:FPPSQLResults];
	if (self.metadata)
		[tempDict setObject:self.metadata forKey:FPPSQLResultsMetadata];
	
	return tempDict;
}

- (void)updateObjectTypesInResults
{
	if (self.columnTypes == nil
		|| [self.columnTypes count] == 0
		|| self.columnHeaders == nil
		|| [self.columnHeaders count] == 0
		|| self.arrayResults == nil
		|| [self.arrayResults count] == 0
		)
	{
		// error
		return;
	}
	
	NSUInteger index;
	NSUInteger arrayIndex;
	
	NSMutableArray *newArray = [NSMutableArray new];

	NSDateFormatter *timeStampFormatter = [NSDateFormatter new];
	[timeStampFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ssx"];

	NSDateFormatter *timeStampWithMiliSecondsFormatter = [NSDateFormatter new];
	[timeStampWithMiliSecondsFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSSx"];

	NSDateFormatter *timeStampWithmsNoZoneFormatter = [NSDateFormatter new];
	[timeStampWithmsNoZoneFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSSSSS"];

	
	NSDateFormatter *dateFormatter = [NSDateFormatter new];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];

	NSDateFormatter *timeFormatter = [NSDateFormatter new];
	[timeFormatter setDateFormat:@"HH:mm:ss"];

	NSDateFormatter *time4Formatter = [NSDateFormatter new];
	[timeFormatter setDateFormat:@"HH:mm:ss.SSSS"];

	NSDateFormatter *time6Formatter = [NSDateFormatter new];
	[timeFormatter setDateFormat:@"HH:mm:ss.SSSSSS"];

	
	for (arrayIndex = 0; arrayIndex < [self.arrayResults count]; arrayIndex++)
	{
		NSArray *currentTuple = [self.arrayResults objectAtIndex:arrayIndex];
		NSMutableDictionary *newTuple = [NSMutableDictionary new];
		
		for (index = 0; index < [self.columnTypes count]; index++)
		{
			NSString *columnHeader = [self.columnHeaders objectAtIndex:index];
			NSInteger columnOid = [[self.columnTypes objectAtIndex:index] integerValue];
			NSString *currentObject = [currentTuple objectAtIndex:index]; //ForKey:columnHeader];
		
			id newValue = nil;
			
			if (columnOid == BOOLOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = nil;
				else if ([currentObject isEqualToString:@"t"])
					newValue = [[NSNumber alloc] initWithBool:YES];
				else
					newValue = [[NSNumber alloc] initWithBool:NO];
				if (newValue == nil)
					newValue = @NO;
			}
			else if (columnOid == INT8OID
					 || columnOid == INT2OID
					 || columnOid == INT4OID
					 || columnOid == OIDOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = nil;
				else
					newValue = [[NSNumber alloc] initWithInteger:[currentObject integerValue]];
				if (newValue == nil)
					newValue = @0;
			}
			else if (columnOid == FLOAT4OID
					 || columnOid == FLOAT8OID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = nil;
				else
					newValue = [[NSNumber alloc] initWithFloat:[currentObject floatValue]];
				if (newValue == nil)
					newValue = @0;
			}
			else if (columnOid == NUMERICOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = nil;
				else
					newValue = [[NSDecimalNumber alloc] initWithString:currentObject];
				if (newValue == nil)
					newValue = [NSDecimalNumber zero];
			}
			else if (columnOid == TIMESTAMPTZOID || columnOid == TIMESTAMPOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = [NSNull null];
				else
				{
					newValue = [timeStampFormatter dateFromString:currentObject];
					newValue = newValue ? newValue : [timeStampWithMiliSecondsFormatter dateFromString:currentObject];
					newValue = newValue ? newValue : [timeStampWithmsNoZoneFormatter dateFromString:currentObject];
				}
				
				//failsafe
				if (newValue == nil)
					newValue = [NSNull null];
			}
			else if (columnOid == DATEOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = [NSNull null];
				else
					newValue = [dateFormatter dateFromString:currentObject];

				//failsafe
				if (newValue == nil)
					newValue = [NSNull null];
			}
			else if (columnOid == TIMEOID || columnOid == TIMETZOID)
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = [NSNull null];
				else
				{
					newValue = [timeFormatter dateFromString:currentObject];
					newValue = newValue ? newValue : [time4Formatter dateFromString:currentObject];
					newValue = newValue ? newValue : [time6Formatter dateFromString:currentObject];
				}
				
				//failsafe
				if (newValue == nil)
					newValue = [NSNull null];
			}
			else
			{
				if ([currentObject isEqual:[NSNull null]])
					newValue = @"";
				else
					newValue = currentObject;
				if (newValue == nil)
					newValue = @"";
			}
			

			[newTuple setObject:newValue forKey:columnHeader];
			
		}
		[newArray addObject:newTuple];
	}
	
#if !__has_feature(objc_arc)
	[timeStampFormatter release];
	[timeStampWithMiliSecondsFormatter release];
	[timeStampWithmsNoZoneFormatter release];
	[dateFormatter release];
	[timeFormatter release];
	[time4Formatter release];
	[time6Formatter release];
#endif
	
	self.arrayResults = newArray;
	
}

@end
