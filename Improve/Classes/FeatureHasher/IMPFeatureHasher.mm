//
//  IMPFeatureHasher.m
//  FeatureHasher
//
//  Created by Vladimir on 1/16/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPFeatureHasher.h"
#import "IMPMurmurHash.h"
#import "NSArray+Padding.h"


@implementation IMPFeatureHasher

- (instancetype)initWithNumberOfFeatures:(NSUInteger)numberOfFeatures
                           alternateSign:(BOOL)alternateSign {
    self = [super init];
    if (self) {
        _numberOfFeatures = numberOfFeatures;
        _alternateSign = alternateSign;

        [self validateParameters];
    }
    return self;
}

- (instancetype)initWithNumberOfFeatures:(NSUInteger)numberOfFeatures {
    return [self initWithNumberOfFeatures:numberOfFeatures alternateSign:true];
}

- (instancetype)init {
    NSUInteger defaultNumberOfFeatures = 1048576;
    return [self initWithNumberOfFeatures:defaultNumberOfFeatures alternateSign:true];
}

- (void)validateParameters {
    if (self.numberOfFeatures < 1 || self.numberOfFeatures > INT_MAX) {
        [[NSException exceptionWithName:@"InvalidParameters"
                                 reason:[NSString stringWithFormat:@"Invalid number of features (%ld).", (long)self.numberOfFeatures]
                               userInfo:nil] raise];
    }
}

- (IMPMatrix *)transform:(NSArray<NSDictionary<NSString*,id>*> *)x {
    IMPMatrix *output = [[IMPMatrix alloc] initWithRows:x.count columns:self.numberOfFeatures];

    for (NSInteger row = 0; row < x.count; row++) {
        NSDictionary *sample = x[row];

        for (__strong NSString *key in sample) {
            id objectVal = sample[key];
            double numberVal = 0;
            if ([objectVal isKindOfClass:[NSString class]]) {
                key = [NSString stringWithFormat:@"%@=%@", key, objectVal];
                numberVal = 1.0;
            } else if ([objectVal isKindOfClass:[NSNumber class]]) {
                numberVal = [objectVal doubleValue];
            } else {
                NSString *reason = [NSString stringWithFormat:@"Invalid type of value (%@) for key %@.", objectVal, key];
                [[NSException exceptionWithName:@"InvalidInput"
                                         reason:reason
                                       userInfo:nil] raise];
                continue;
            }

            if (numberVal == 0) {
                continue;
            }

            NSInteger h = (int32_t)[IMPMurmurHash hash32:key];

            if (self.shouldAlternateSign && h < 0) {
                numberVal = -numberVal;
            }

            NSInteger index = abs(h) % self.numberOfFeatures;
            double currentVal = [output valueAtRow:row column:index];
            [output setValue:(currentVal + numberVal) atRow:row column:index];
        }
    }

    return output;
}

@end
