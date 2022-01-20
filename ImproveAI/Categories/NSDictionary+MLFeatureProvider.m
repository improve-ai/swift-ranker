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

MLFeatureValue * NaNMLFeatureValue = nil;

@interface NSDictionary (MLFeatureProvider)

@property (strong, nonatomic) NSSet<NSString *> *featureNames;

@end

@implementation NSDictionary (MLFeatureProvider)

- (instancetype)initWithFeatureNames:(NSSet<NSString *> *)featureNames {
    if(self = [self init]) {
        self.featureNames = featureNames;
        if(NaNMLFeatureValue ==  nil){
            NaNMLFeatureValue =  [MLFeatureValue featureValueWithDouble:NAN];
        }
    }
    return self;
}

- (void)setFeatureNames:(NSSet<NSString *> *)modelFeatureNames {
    objc_setAssociatedObject(self, sFeatureNameKey, modelFeatureNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSSet<NSString *> *)featureNames{
    return objc_getAssociatedObject(self, sFeatureNameKey);
}

#pragma mark MLFeatureProvider Protocol

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName {
    MLFeatureValue *val = self[featureName];
    if(val) {
        // In order to be able to perform 'correct' comparisons (obtain exactly
        // identical split results to those of native pure xgboost) inputs must
        // be converted to float32 prior to predct() call
        float correctedVal = (float)[val doubleValue];
        val = [MLFeatureValue featureValueWithDouble:correctedVal];
    }
    return val ? val : NaNMLFeatureValue;
}

@end
