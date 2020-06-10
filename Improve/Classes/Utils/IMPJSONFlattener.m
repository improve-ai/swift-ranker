//
//  IMPJSONFlattener.m
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPJSONFlattener.h"

NSString * const kDefaultSeparator = @"";

@implementation IMPJSONFlattener

- (instancetype)init {
    self = [super init];
    if (self) {
        _separator = kDefaultSeparator;
    }
    return self;
}

- (NSData * _Nullable)flatten:(NSData *)jsonData
                        error:(NSError * _Nullable *)error
{
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                    options:0
                                                      error:error];
    if (jsonObject == nil) { return nil; }
    
    NSDictionary *flatObject = [self flatten:jsonObject];
    NSData *outputData = [NSJSONSerialization dataWithJSONObject:flatObject
                                                         options:0
                                                           error:error];
    return outputData;
}

- (NSDictionary *)flatten:(id)jsonObject
{
    NSMutableDictionary *rootDict = [NSMutableDictionary new];
    [self flatten:jsonObject
               to:rootDict
           prefix:@""];
    return rootDict;
}

- (void)flatten:(id)jsonObject
             to:(NSMutableDictionary *)dictionary
         prefix:(NSString *)prefix
{
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *jsonDict = jsonObject;
        if (jsonDict.count == 0 && self.emptyDictionaryValue) {
            dictionary[prefix] = self.emptyDictionaryValue;
            return;
        }
        for (NSString *key in jsonDict) {
            id val = jsonDict[key];
            NSString *nextPrefix = [self extendPrefix:prefix withKey:key separator:self.separator];
            [self flatten:val
                       to:dictionary
                   prefix:nextPrefix];
        }
    } else if ([jsonObject isKindOfClass:[NSArray class]]) {
        NSArray *jsonArray = jsonObject;
        if (jsonArray.count == 0 && self.emptyArrayValue) {
            dictionary[prefix] = self.emptyArrayValue;
            return;
        }
        for (NSInteger i = 0; i < jsonArray.count; i++) {
            id val = jsonArray[i];
            NSString *key = [NSString stringWithFormat:@"%ld", i];
            NSString *nextPrefix = [self extendPrefix:prefix withKey:key separator:self.separator];
            [self flatten:val
                       to:dictionary
                   prefix:nextPrefix];
        }
    } else {
        // Not a collection, use "as is"
        dictionary[prefix] = jsonObject;
    }
}

- (NSString *)extendPrefix:(NSString *)prefix
                   withKey:(NSString *)key
                 separator:(NSString *)separator
{
    if (prefix.length == 0) {
        return key;
    } else {
        return [NSString stringWithFormat:@"%@%@%@", prefix, separator, key];
    }
}

@end
