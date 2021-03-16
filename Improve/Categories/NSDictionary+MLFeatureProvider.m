//
//  NSDictionary+MLFeatureProvider.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 3/15/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "NSDictionary+MLFeatureProvider.h"

@implementation NSDictionary (MLFeatureProvider)

- (id)initWithFeatureNames:(NSSet<NSString *> *)featureNames
{
    if(self = [super init]){
        _featureNames = featureNames;
        _nan = [MLFeatureValue featureValueWithDouble:NAN]; // memoize a single NaN MLFeatureValue object // TODO can this be moved to class scope so its shared across feature provider instances?
    }
    return self;
}

- (MLFeatureValue *)featureValueForName:(NSString *)featureName
{
    NSNumber *val = self[featureName];
    if (val != nil) {
        return [MLFeatureValue featureValueWithDouble:val.doubleValue];
    }
    
    return _nan;
}

@end
