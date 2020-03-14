//
//  IMPJSONUtils.h
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPJSONUtils : NSObject

+ (nullable id)objectFromString:(NSString *)jsonString;

+ (nullable id)objectFromString:(NSString *)jsonString error:(NSError **)error;

/// Convert keys to NSNumber integers.
+ (NSDictionary<NSNumber*, id> *)convertKeysToIntegers:(NSDictionary *)inputJSON;

@end

NS_ASSUME_NONNULL_END
