//
//  NSDictionary+MLFeatureProvider.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 3/15/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <objc/runtime.h>
#import "NSDictionary+MLFeatureProvider.h"

static void *sDictionaryKey = &sDictionaryKey;

@implementation NSDictionary (MLFeatureProvider)

- (void)setMLFeatures:(NSDictionary<NSString *,MLFeatureValue *> *)MLFeatures{
    objc_setAssociatedObject(self, sDictionaryKey, MLFeatures, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary<NSString *,MLFeatureValue *> *)MLFeatures{
    return objc_getAssociatedObject(self, sDictionaryKey);
}

#pragma mark MLFeatureProvider

- (NSSet<NSString *> *)featureNames{
    if(self.MLFeatures == nil){
        [self initMLFeatures];
    }
    return [[NSSet alloc] initWithArray:[self.MLFeatures allKeys]];
}

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName{
    if(self.MLFeatures == nil){
        [self initMLFeatures];
    }
    return self.MLFeatures[featureName];
}

- (void)initMLFeatures{
    NSMutableDictionary *prefixedValues = [NSMutableDictionary dictionaryWithCapacity:self.count];

    MLFeatureValue *nan = [MLFeatureValue featureValueWithDouble:NAN];
    for (NSUInteger i = 0; i < 254; i++)
    {
        NSString *key = [NSString stringWithFormat:@"%@%ld", @"f", i];

        NSNumber *numbVal = self[@(i)];
        MLFeatureValue *val;
        if (numbVal != nil) {
            val = [MLFeatureValue featureValueWithDouble:val.doubleValue];
        } else {
            val = nan;
        }
        prefixedValues[key] = val;
    }
    self.MLFeatures = prefixedValues;
}



@end
