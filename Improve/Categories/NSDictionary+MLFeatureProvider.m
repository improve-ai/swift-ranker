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

static void *sMLFeatureKey = &sMLFeatureKey;

@interface NSDictionary (MLFeatureProvider)

@property (readonly, nonatomic) NSDictionary<NSString *, MLFeatureValue *> *MLFeatures;

@property (strong, nonatomic) NSSet<NSString *> *featureNames;

@end

@implementation NSDictionary (MLFeatureProvider)

- (instancetype)initWithFeatureNames:(NSSet<NSString *> *)featureNames{
    if(self = [self init]){
        self.featureNames = featureNames;
    }
    return self;
}

- (void)setMLFeatures:(NSDictionary<NSString *,MLFeatureValue *> *)MLFeatures{
    objc_setAssociatedObject(self, sMLFeatureKey, MLFeatures, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDictionary<NSString *,MLFeatureValue *> *)MLFeatures{
    return objc_getAssociatedObject(self, sMLFeatureKey);
}

- (void)setFeatureNames:(NSSet<NSString *> *)modelFeatureNames{
    objc_setAssociatedObject(self, sFeatureNameKey, modelFeatureNames, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSSet<NSString *> *)featureNames{
    return objc_getAssociatedObject(self, sFeatureNameKey);
}

#pragma mark MLFeatureProvider Protocol

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName{
    if(self.MLFeatures == nil){
        [self initMLFeatures];
    }
    return self.MLFeatures[featureName];
}

- (void)initMLFeatures{
    NSMutableDictionary *mlFeatures = [NSMutableDictionary dictionaryWithCapacity:self.featureNames.count];
    
    MLFeatureValue *nanFeatureValue = [MLFeatureValue featureValueWithDouble:NAN];
    
    for(NSString *featureName in self.featureNames){
        MLFeatureValue *val = self[featureName];
        if(val == nil){
            val = nanFeatureValue;
        }
        mlFeatures[featureName] = val;
    }
    
    self.MLFeatures = mlFeatures;
}

@end
