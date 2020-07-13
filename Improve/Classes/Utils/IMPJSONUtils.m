//
//  IMPJSONUtils.m
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPJSONUtils.h"
#import "IMPJSONFlattener.h"
#import "IMPLogging.h"

@implementation IMPJSONUtils

+ (id)objectFromString:(NSString *)jsonString
{
    return [self objectFromString:jsonString error:NULL];
}

+ (id)objectFromString:(NSString *)jsonString error:(NSError **)error
{
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
}

+ (NSDictionary<NSNumber*, id> *)convertKeysToIntegers:(NSDictionary *)inputJSON
{
    NSMutableDictionary *outJSON = [NSMutableDictionary dictionaryWithCapacity:inputJSON.count];
    for (id key in inputJSON)
    {
        NSString *keyStr = [NSString stringWithFormat:@"%@", key];
        NSScanner *scanner = [NSScanner scannerWithString:keyStr];
        NSInteger intKey = 0;
        if (![scanner scanInteger:&intKey]) {
            IMPLog("Key '%@' can't be converted to int! Skipped.", key);
            continue;
        }
        outJSON[@(intKey)] = inputJSON[key];
    }
    return outJSON;
}

@end
