//
//  NSDictionary+MLFeatureProvider.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 3/15/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <objc/runtime.h>
#import "NSDictionary+MLFeatureProvider.h"

static void *sFeatureNameKey = &sFeatureNameKey;

@interface NSDictionary (MLFeatureProvider)

@property (strong, nonatomic) NSSet<NSString *> *featureNames;

@end

@implementation NSDictionary (MLFeatureProvider)

- (instancetype)initWithFeatureNames:(NSSet<NSString *> *)featureNames{
    if(self = [self init]){
        self.featureNames = featureNames;
    }
    return self;
}

- (void)setFeatureNames:(NSSet<NSString *> *)modelFeatureNames{
    objc_setAssociatedObject(self, sFeatureNameKey, modelFeatureNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSSet<NSString *> *)featureNames{
    return objc_getAssociatedObject(self, sFeatureNameKey);
}

#pragma mark MLFeatureProvider Protocol
// Returns the value of the feature, or nil if no value exists for that name.
- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName{
    if(self[featureName] == nil){
        return nil;
    } else {
        return [MLFeatureValue featureValueWithDouble:[self[featureName] doubleValue]];
    }
}

@end
