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

+ (NSString *)jsonStringOrDerscriptionOf:(NSObject *)object
{
    NSString *string = [NSString stringWithFormat:@"#json encoding error# %@", object];
    if (![NSJSONSerialization isValidJSONObject:object]) return string;

    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:NSJSONWritingPrettyPrinted error:nil];
    if (!data) return string;

    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!jsonString) return string;
    return jsonString;
}

@end
