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
    NSMutableDictionary *features = [NSMutableDictionary dictionaryWithCapacity:self.count];
    for(NSString *featureName in self){
        MLFeatureValue *val = [MLFeatureValue featureValueWithDouble:[self[featureName] doubleValue]];
        features[featureName] = val;
    }
    self.MLFeatures = features;
}

@end
