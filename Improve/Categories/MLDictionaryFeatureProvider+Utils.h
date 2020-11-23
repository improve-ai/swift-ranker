//
//  MLDictionaryFeatureProvider+Utils.h
//  ImproveUnitTests
//
//  Created by Vladimir on 3/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLDictionaryFeatureProvider (Utils)

/**
 Initializes dictionary with array values and keys in the following format: "prefix" + "index".
 */
- (nullable instancetype)initWithArray:(NSArray *)array prefix:(NSString *)prefix error:(NSError **)error;

/**
 Initializes itself with the `encodedFeatures` dictionary. Dictionary keys are prefixed with the `prefix`. Features count is required in order to fill missing features (which are possible) with NAN. Note that `encodedFeatures.count` may be smaller than `featuresCount`.
 */
- (nullable instancetype)initWithEncodedFeatures:(NSDictionary<NSNumber*, NSNumber*> *)encodedFeatures
                                          prefix:(NSString *)prefix
                                           count:(NSUInteger)featuresCount
                                           error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
