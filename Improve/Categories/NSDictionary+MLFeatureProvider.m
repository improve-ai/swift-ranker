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

MLFeatureValue * NaNValue = nil;

@interface NSDictionary (MLFeatureProvider)

@property (strong, nonatomic) NSSet<NSString *> *featureNames;

@end

@implementation NSDictionary (MLFeatureProvider)

- (instancetype)initWithFeatureNames:(NSSet<NSString *> *)featureNames{
    if(self = [self init]){
        self.featureNames = featureNames;
        if(NaNValue ==  nil){
            NaNValue =  [MLFeatureValue featureValueWithDouble:NAN];
        }
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

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName{
    MLFeatureValue *val = self[featureName];
    if(val == nil){
        val = NaNValue;
    }
    return val;
}

@end
