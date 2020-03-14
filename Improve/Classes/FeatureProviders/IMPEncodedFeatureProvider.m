//
//  IMPEncodedFeatureProvider.m
//  ImproveUnitTests
//
//  Created by Vladimir on 3/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPEncodedFeatureProvider.h"

@implementation IMPEncodedFeatureProvider {
    NSSet<NSString*> *_featureNames;
}

- (instancetype)initWithDictionary:(NSDictionary<NSNumber *,id> *)dictionary
                            prefix:(NSString *)prefix
                             count:(NSUInteger)featuresCount
{
    self = [super init];
    if (self) {
        _dictionary = dictionary;
        _featureNamePrefix = prefix;
        _featuresCount = featuresCount;
    }
    return self;
}

- (NSSet<NSString *> *)featureNames {
    if (_featureNames) return _featureNames;

    NSMutableSet *names = [NSMutableSet new];
    for (NSUInteger i = 0; i < self.featuresCount; i++) {
        [names addObject:[NSString stringWithFormat:@"%@%ld", self.featureNamePrefix, i]];
    }
    _featureNames = names;
    return names;
}

- (MLFeatureValue *)featureValueForName:(NSString *)featureName
{
    NSUInteger prefixLength = self.featureNamePrefix.length;
    NSInteger featureIndex = [[featureName substringFromIndex:prefixLength] integerValue];
    NSNumber *val = self.dictionary[@(featureIndex)];
    if (val) {
        return [MLFeatureValue featureValueWithDouble:val.doubleValue];
    } else {
        return [MLFeatureValue featureValueWithDouble:NAN];
    }
}

@end
