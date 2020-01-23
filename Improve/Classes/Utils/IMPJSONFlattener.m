//
//  IMPJSONFlattener.m
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPJSONFlattener.h"

NSString * const kDefaultSeparator = @"_";

@implementation IMPJSONFlattener

+ (NSData * _Nullable)flatten:(NSData *)jsonData
                    separator:(NSString *)separator
                        error:(NSError * _Nullable *)error
{
  id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                  options:0
                                                    error:error];
  if (jsonObject == nil) { return nil; }

  NSDictionary *flatObject = [self flatten:jsonObject separator:separator];
  NSData *outputData = [NSJSONSerialization dataWithJSONObject:flatObject
                                                       options:0
                                                         error:error];
  return outputData;
}

+ (NSDictionary *)flatten:(id)jsonObject
                separator:(NSString *)separator
{
  NSMutableDictionary *rootDict = [NSMutableDictionary new];
  [self flatten:jsonObject
             to:rootDict
      separator:separator
         prefix:@""];
  return rootDict;
}

+ (void)flatten:(id)jsonObject
             to:(NSMutableDictionary *)dictionary
      separator:(NSString *)separator
         prefix:(NSString *)prefix
{
  if ([jsonObject isKindOfClass:[NSDictionary class]]) {
    NSDictionary *jsonDict = jsonObject;
    for (NSString *key in jsonDict) {
      id val = jsonDict[key];
      NSString *nextPrefix = [self extendPrefix:prefix withKey:key separator:separator];
      [self flatten:val
                 to:dictionary
          separator:separator
             prefix:nextPrefix];
    }
  } else if ([jsonObject isKindOfClass:[NSArray class]]) {
    NSArray *jsonArray = jsonObject;
    for (NSInteger i = 0; i < jsonArray.count; i++) {
      id val = jsonArray[i];
      NSString *key = [NSString stringWithFormat:@"%ld", i];
      NSString *nextPrefix = [self extendPrefix:prefix withKey:key separator:separator];
      [self flatten:val
             to:dictionary
      separator:separator
         prefix:nextPrefix];
    }
  } else {
    // Not a collection, use "as is"
    dictionary[prefix] = jsonObject;
  }
}

+ (NSString *)extendPrefix:(NSString *)prefix
                   withKey:(NSString *)key
                 separator:(NSString *)separator
{
  if (prefix.length == 0) {
    return key;
  } else {
    return [NSString stringWithFormat:@"%@%@%@", prefix, separator, key];
  }
}

+ (NSDictionary * _Nullable)flatten:(id)jsonObject {
  return [self flatten:jsonObject separator:kDefaultSeparator];
}

@end
