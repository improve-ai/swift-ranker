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

+ (NSDictionary<NSString*, id> *)propertiesToFeatures:(id)jsonObject
                                           withPrefix:(NSString *)prefix;

+ (NSDictionary<NSString*, id> *)propertiesToFeatures:(id)jsonObject;

/**
 @return A primitive type if the value is primitive or the value of the “id” field if it is a NSDictionary, otherwise throw an UnsupportedInput exception.
 */
+ (NSString *)variantToCanonical:(id)variant;

@end

NS_ASSUME_NONNULL_END
