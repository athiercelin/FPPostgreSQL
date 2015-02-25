//
//  FPRequest.m
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

#import "FPRequest.h"


@implementation FPRequest


#pragma mark Get the request's results
+ (NSDictionary *)getResultsFromSelectRequestWithPGResult:(PGresult *)pgresult
{
	char					*title;
	NSInteger				columnCounter;
	NSInteger				rowCounter;
	NSInteger				rows = PQntuples(pgresult);
	NSInteger				columns = PQnfields(pgresult);
	NSMutableArray			*header = [NSMutableArray new];	
	NSMutableArray	 		*preResultsList = [NSMutableArray new];	
	NSDictionary			*results = nil;
	
	for (columnCounter = 0; columnCounter < columns; columnCounter++) 
	{
		//Get columns name
		title = PQfname(pgresult, columnCounter);
		[header addObject:[NSString stringWithFormat:@"%s", title]];
	}
	
	for (rowCounter = 0; rowCounter < rows; rowCounter++) 
	{
		NSMutableDictionary	*rowValues = [NSMutableDictionary new];
		
		for (columnCounter = 0; columnCounter < columns; columnCounter++) 
		{
			char		*bufValue = 0;
			Oid 		colType;
			
			bufValue = PQgetvalue(pgresult, rowCounter, columnCounter);
			colType = PQftype(pgresult, columnCounter);
			if (colType == BOOLOID) 
			{
				if (bufValue[0] == 't') 
				{
					NSNumber	*value = [[NSNumber alloc] initWithBool:YES];
					char		*preKey = PQfname(pgresult, columnCounter);
					NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
					
					[rowValues setObject:value forKey:key];
					[key release];
					[value release];
				} 
				else 
				{
					NSNumber 	*value = [[NSNumber alloc] initWithBool:NO];
					char		*preKey = PQfname(pgresult, columnCounter);
					NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
					
					[rowValues setObject:value forKey:key];
					[key release];
					[value release];
				}
			} 
			else if (colType == INT8OID || colType == INT2OID || colType == INT4OID) 
			{
				NSInteger	preVal = atoi(bufValue);
				NSNumber	*value = [[NSNumber alloc] initWithInteger:preVal];
				char		*preKey = PQfname(pgresult, columnCounter);
				NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];
			} 
			else if (colType == FLOAT4OID) 
			{
				float			preVal = atof(bufValue); // * 1000000;
				NSDecimalNumber	*value = [[NSDecimalNumber alloc] initWithFloat:preVal];
										  /*
										  initWithMantissa:preVal 
										  exponent:-6
										  isNegative:preVal >= 0 ? NO : YES];
										   */
				char			*preKey = PQfname(pgresult, columnCounter);
				NSString 		*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];				
			} 
			else if (colType == FLOAT8OID) 
			{
				double			preVal = atof(bufValue); // * 1000000;
				NSDecimalNumber	*value = [[NSDecimalNumber alloc] initWithDouble:preVal];
										  /*
										   initWithMantissa:preVal 
										   exponent:-6
										   isNegative:preVal >= 0 ? NO : YES];
										   */
				char			*preKey = PQfname(pgresult, columnCounter);
				NSString 		*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];
			} 
			else if (colType == NUMERICOID) 
			{
				NSDecimalNumber	*value = [[NSDecimalNumber alloc] initWithString:[NSString stringWithFormat:@"%s", 
																				  (bufValue && strlen(bufValue) > 0) ? bufValue : "0"]];
				char		*preKey = PQfname(pgresult, columnCounter);
				NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];				
			} 
			else if (colType == OIDOID) 
			{				
				NSInteger	preVal = atoi(bufValue);
				NSNumber	*value = [[NSNumber alloc] initWithInteger:preVal];
				char		*preKey = PQfname(pgresult, columnCounter);
				NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];				
			} 
			else if (colType == TIMESTAMPTZOID || colType == TIMESTAMPOID) 
			{				
				NSString			*preDate = [[NSString alloc] initWithCString:bufValue encoding:NSUTF8StringEncoding];
				char				*preKey;
				NSString 			*key = nil;
				id					value = [[[NSCalendarDate alloc] initWithString:preDate
														calendarFormat:@"%Y-%m-%d %H:%M:%S"] autorelease];
				
				if (value == nil)
					value = [NSNull null];
				
				preKey = PQfname(pgresult, columnCounter);
				key = [[NSString alloc] initWithFormat:@"%s", preKey];
				[rowValues setObject:value forKey:key];
				[key release];
				[preDate release];
	
			} 
			else if (colType == DATEOID) 
			{				
				NSString			*preDate = [[NSString alloc] initWithCString:bufValue encoding:NSUTF8StringEncoding];
				char				*preKey;
				NSString 			*key = nil;
				id					value = [[[NSCalendarDate alloc] initWithString:preDate
														calendarFormat:@"%Y-%m-%d"] autorelease];
				
				if (value == nil)
					value = [NSNull null];
				
				preKey = PQfname(pgresult, columnCounter);
				key = [[NSString alloc] initWithFormat:@"%s", preKey];
				[rowValues setObject:value forKey:key];
				[key release];
				[preDate release];

			} 
			else if (colType == TIMEOID || colType == TIMETZOID) 
			{				
				NSString			*preDate = [[NSString alloc] initWithCString:bufValue encoding:NSUTF8StringEncoding];
				char				*preKey;
				NSString 			*key = nil;
				id					value = [[[NSCalendarDate alloc] initWithString:preDate
														calendarFormat:@"%H:%M:%S"] autorelease];
				
				if (value == nil)
					value = [NSNull null];
				
				preKey = PQfname(pgresult, columnCounter);
				key = [[NSString alloc] initWithFormat:@"%s", preKey];
				[rowValues setObject:value forKey:key];
				[key release];
				[preDate release];
				
			} 
			else 
			{					
				// Insert here other type analysis
				NSString	*value = [[NSString alloc] initWithCString:bufValue encoding:NSUTF8StringEncoding];
				char		*preKey = PQfname(pgresult, columnCounter);
				NSString 	*key = [[NSString alloc] initWithFormat:@"%s", preKey];
				
				[rowValues setObject:value forKey:key];
				[key release];
				[value release];
			}
		}
		[preResultsList addObject:rowValues];
		[rowValues release];
	}	
	
	//Return results
	results = [[NSDictionary alloc] initWithObjectsAndKeys:
			   [NSArray arrayWithArray:header], FPPSQLResultsColumnHeaders, 
			   [NSArray arrayWithArray:preResultsList], FPPSQLResults, nil];
	[header release];
	[preResultsList release];
	return results;
}

+ (NSDictionary *)getResultsFromEditRequestWithPGResult:(PGresult *)pgresult
{
	//If an Error occurs when get the result back
	if (PQresultStatus(pgresult) != PGRES_COMMAND_OK && 
		PQresultStatus(pgresult) != PGRES_TUPLES_OK) 
	{
		char			*preErrorMsg = PQresultErrorMessage(pgresult);
		
#ifdef PG_DEBUG
		//	NSLog(@"%s:%s", __FILE__, preErrorMsg);
#endif
		
		return [[NSDictionary alloc] initWithObjectsAndKeys:
				[NSString stringWithFormat:@"%s", preErrorMsg], FPPSQLResultsError, 
				nil];
	}
	
	//Return the row's number which has been modified
	if (PQresultStatus(pgresult) == PGRES_COMMAND_OK) 
	{
#ifdef PG_DEBUG
		//	NSLog(@"%s: cmdTuples:%s", __FILE__, PQcmdTuples(pgresult));
#endif
		
		//Return the rows number
		NSNumber 	*nbRows = [NSNumber numberWithInt:atoi(PQcmdTuples(pgresult))];
		
#ifdef PG_DEBUG
		//	NSLog(@"%s: NbRows:%@", __FILE__, nbRows);
#endif
		return [[NSDictionary alloc] initWithObjectsAndKeys:
				nbRows, FPPSQLResults, 
				nil];
	}
	

	return nil;
}

@end
