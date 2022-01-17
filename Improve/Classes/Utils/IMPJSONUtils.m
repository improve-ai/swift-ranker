//
//  IMPJSONUtils.m
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPJSONUtils.h"

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

+ (NSString *)jsonStringOrDescriptionOf:(NSObject *)object
{
    return [self jsonStringOrDescriptionOf:object condensed:YES];
}

+ (NSString *)jsonStringOrDescriptionOf:(NSObject *)object
                               condensed:(BOOL)condensed
{
    NSString *description = [NSString stringWithFormat:@"%@", object];
    if (condensed) {
        description = [[description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    }

    if (![NSJSONSerialization isValidJSONObject:object]) return description;

    NSJSONWritingOptions options = condensed ? 0 : NSJSONWritingPrettyPrinted;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:options error:nil];
    if (!data) return description;

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonString) return description;
    return jsonString;
}

@end
