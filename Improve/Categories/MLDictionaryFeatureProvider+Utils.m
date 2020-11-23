//
//  MLDictionaryFeatureProvider+Utils.m
//  ImproveUnitTests
//
//  Created by Vladimir on 3/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "MLDictionaryFeatureProvider+Utils.h"


@implementation MLDictionaryFeatureProvider (Utils)

- (nullable instancetype)initWithArray:(NSArray *)array
                                prefix:(NSString *)prefix
                                 error:(NSError **)error
{
    NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:array.count];
    for (NSInteger i = 0; i < array.count; i++)
    {
        NSString *key = [NSString stringWithFormat:@"%@%ld", prefix, i];
        values[key] = array[i];
    }

    self = [self initWithDictionary:values error:error];
    return self;
}

- (nullable instancetype)initWithEncodedFeatures:(NSDictionary<NSNumber*, NSNumber*> *)encodedFeatures
                                          prefix:(NSString *)prefix
                                           count:(NSUInteger)featuresCount
                                           error:(NSError **)error
{
    if (featuresCount < encodedFeatures.count)
    {
        NSString *errMsg = @"Bad input, `featuresCount` should be greater or equal to `encodedFeatures.count`!";
        if (error != NULL) *error = [NSError errorWithDomain:@"ai.improve.MLDictionaryFeatureProvider+Utils" code:-100 userInfo:@{NSLocalizedDescriptionKey: errMsg}];
        return nil;
    }

    // Dictionary of MLFeatureValue instances.
    NSMutableDictionary *prefixedValues = [NSMutableDictionary dictionaryWithCapacity:featuresCount];

    for (NSUInteger i = 0; i < featuresCount; i++)
    {
        NSString *key = [NSString stringWithFormat:@"%@%ld", prefix, i];

        NSNumber *numbVal = encodedFeatures[@(i)];
        MLFeatureValue *val;
        if (numbVal != nil) {
            val = [MLFeatureValue featureValueWithDouble:val.doubleValue];
        } else {
            val = [MLFeatureValue featureValueWithDouble:NAN];
        }

        prefixedValues[key] = val;
    }

    self = [self initWithDictionary:prefixedValues error:error];
    return self;
}

@end
