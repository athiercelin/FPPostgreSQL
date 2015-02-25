//
//  CLPSQLIdentifiers.h
//  CLPostgreSQL.framework
//
//  Created by Flying Pig on 2/19/07.
//  Copyright © 2007 Flying Pig. All rights reserved.
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



//Identifiers
#define FPPSQLResults															@"FPPSQLResults"
#define FPPSQLResultsError														@"FPPSQLResultsError"
#define FPPSQLResultsMetadata													@"FPPSQLResultsMetadata"
#define FPPSQLResultsColumnHeaders												@"FPPSQLResultsColumnHeaders"
#define FPPSQLResultsColumnTypes												@"FPPSQLResultsColumnTypes"


//Errors
#define FPPSQLConnectionFailed													@"Connection Failed"
#define FPPSQLBadParameter														@"Bad parameter"
#define FPPSQLExecutionFailed													@"Execution failed"
#define FPPSQLOperationCancelled												@"Operation cancelled"


#ifndef __FPPSQLIdentifiers__
#define __FPPSQLIdentifiers__

//Format's values
typedef enum {
	FPPSQLTextParamFormatsEnum = 0,
	FPPSQLBinParamFormatsEnum = 1
} FPPSQLParamFormatsEnum;

//Priorities
enum {
	FPRequestQueuePriorityVeryLow = NSOperationQueuePriorityVeryLow,
	FPRequestQueuePriorityLow = NSOperationQueuePriorityLow,
	FPRequestQueuePriorityNormal = NSOperationQueuePriorityNormal,
	FPRequestQueuePriorityHigh = NSOperationQueuePriorityHigh,
	FPRequestQueuePriorityVeryHigh = NSOperationQueuePriorityVeryHigh
};
typedef NSOperationQueuePriority FPRequestQueuePriority;


#endif

#if TARGET_OS_IPHONE

#else
#import <FPPostgreSQL/FPPostgreSQL.h>
#endif

// Define OID Type
#define BOOLOID																	16
#define BYTEAOID																17
#define CHAROID																	18
#define NAMEOID																	19
#define INT8OID																	20
#define INT2OID																	21
#define INT2VECTOROID															22
#define INT4OID																	23
#define REGPROCOID																24
#define TEXTOID																	25
#define OIDOID																	26
#define TIDOID																	27
#define XIDOID																	28
#define CIDOID																	29
#define OIDVECTOROID															30
#define PG_TYPE_RELTYPE_OID														71
#define PG_ATTRIBUTE_RELTYPE_OID												75
#define PG_PROC_RELTYPE_OID														81
#define PG_CLASS_RELTYPE_OID													83
#define POINTOID																600
#define LSEGOID																	601
#define PATHOID																	602
#define BOXOID																	603
#define POLYGONOID																604
#define LINEOID																	628
#define CIDROID																	650
#define FLOAT4OID																700
#define FLOAT8OID																701
#define ABSTIMEOID																702
#define RELTIMEOID																703
#define TINTERVALOID															704
#define UNKNOWNOID																705
#define CIRCLEOID																718
#define CASHOID																	790
#define MACADDROID																829
#define INETOID																	869
#define INT4ARRAYOID															1007
#define ACLITEMOID																1033
#define BPCHAROID																1042
#define VARCHAROID																1043
#define DATEOID																	1082
#define TIMEOID																	1083
#define TIMESTAMPOID															1114
#define TIMESTAMPTZOID															1184
#define INTERVALOID																1186
#define TIMETZOID																1266
#define BITOID																	1560
#define VARBITOID																1562
#define NUMERICOID																1700
#define REFCURSOROID															1790
#define REGPROCEDUREOID															2202
#define REGOPEROID																2203
#define REGOPERATOROID															2204
#define REGCLASSOID																2205
#define REGTYPEOID																2206
#define RECORDOID																2249
#define CSTRINGOID																2275
#define ANYOID																	2276
#define ANYARRAYOID																2277
#define VOIDOID																	2278
#define TRIGGEROID																2279
#define LANGUAGE_HANDLEROID														2280
#define INTERNALOID																2281
#define OPAQUEOID																2282
#define ANYELEMENTOID															2283

