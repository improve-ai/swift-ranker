//
//  NSDictionary+MLFeatureProvider.h
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 3/15/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (MLFeatureProvider) <MLFeatureProvider>

@property(readonly, nonatomic) NSSet<NSString *> *featureNames;

- (id)initWithFeatureNames:(NSSet<NSString *> *)featureNames;

- (MLFeatureValue *)featureValueForName:(NSString *)featureName;

@end

NS_ASSUME_NONNULL_END
