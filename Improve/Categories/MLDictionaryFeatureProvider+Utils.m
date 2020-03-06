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

- (nullable instancetype)initWithDictionary:(NSDictionary<NSNumber*, id> *)dictionary
                                     prefix:(NSString *)prefix
                                      error:(NSError **)error
{
    NSMutableDictionary *stringDict = [NSMutableDictionary dictionaryWithCapacity:dictionary.count];
    for (NSNumber *nKey in dictionary) {
        NSString *sKey = [NSString stringWithFormat:@"%@%@", prefix, nKey];
        stringDict[sKey] = dictionary[nKey];
    }

    self = [self initWithDictionary:stringDict error:error];
    return self;
}

@end
