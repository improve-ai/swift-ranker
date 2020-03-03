//
//  IMPJSONUtils.m
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPJSONUtils.h"
#import "IMPJSONFlattener.h"

@implementation IMPJSONUtils

+ (NSDictionary<NSString*, id> *)propertiesToFeatures:(id)jsonObject
                                           withPrefix:(NSString *)prefix {
    NSDictionary *flatJSON = [IMPJSONFlattener flatten:jsonObject separator:@"."];
    if (!prefix) { prefix = @""; }
    
    NSMutableDictionary *features = [[NSMutableDictionary alloc] initWithCapacity:flatJSON.count];
    for (NSString *key in flatJSON) {
        id value = flatJSON[key];
        NSString *prefixKey = [NSString stringWithFormat:@"%@%@", prefix, key];
        
        if ([value isKindOfClass:[NSNumber class]]) {
            NSNumber *number = value;
            if (strcmp(number.objCType, @encode(BOOL)) == 0) {
                // BOOL
                NSString *stringBool = [number boolValue] ? @"true" : @"false";
                NSString *oneHotKey = [NSString stringWithFormat:@"%@=%@", prefixKey, stringBool];
                features[oneHotKey] = [NSNumber numberWithDouble:1];
            } else {
                // Numbers: int, float, etc.
                // Double has 64 bits just like Python float type.
                features[prefixKey] = [NSNumber numberWithDouble:number.doubleValue];
            }
        } else if ([value isKindOfClass:[NSNull class]]) {
            // Null
            NSString *oneHotKey = [NSString stringWithFormat:@"%@=null", prefixKey];
            features[oneHotKey] = [NSNumber numberWithDouble:1];
        } else {
            // Other (including strings and dates)
            NSString *oneHotKey = [NSString stringWithFormat:@"%@=%@", prefixKey, value];
            features[oneHotKey] = [NSNumber numberWithDouble:1];
        }
    }
    
    return features;
}

+ (NSDictionary<NSString*, id> *)propertiesToFeatures:(id)jsonObject {
    return [self propertiesToFeatures:jsonObject withPrefix:@""];
}

+ (NSString *)variantToCanonical:(id)variant
{
    NSException *unsupportedInput
    = [NSException exceptionWithName:@"UnsupportedInput"
                              reason:@"JSON input withou 'id' parameter is unsupported"  userInfo:nil];
    
    if ([variant isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = variant;
        
        id identifier = dict[@"id"];
        if (identifier && [identifier isKindOfClass:[NSString class]]) {
            return identifier;
        } else {
            [unsupportedInput raise];
        }
        
    } else if ([variant isKindOfClass:[NSArray class]]) {
        [unsupportedInput raise];
        
    } else {
        // Return a basic type as a string
        return [NSString stringWithFormat:@"%@", variant];
    }
    
    return nil;
}

@end
