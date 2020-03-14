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

@end

NS_ASSUME_NONNULL_END
