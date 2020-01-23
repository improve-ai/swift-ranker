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

- (NSArray<NSArray<NSString*>*> *)transform:(NSArray<NSDictionary<NSString*,id>*> *)x {
  // 2D Matrix of size numberOfSamples x numberOfFeatures
  NSMutableArray *output = [[NSMutableArray alloc] init];

  for (NSDictionary *sample in x) {
    NSMutableArray *row
    = [[NSMutableArray alloc] initWithPadding:[NSNumber numberWithInt:0]
                                        count:self.numberOfFeatures];
    for (__strong NSString *key in sample) {
      id objectVal = sample[key];
      NSNumber *numberVal;
      if ([objectVal isKindOfClass:[NSString class]]) {
        key = [NSString stringWithFormat:@"%@=%@", key, objectVal];
        numberVal = [NSNumber numberWithInt:1];
      } else if ([objectVal isKindOfClass:[NSNumber class]]) {
        numberVal = objectVal;
      } else {
        [[NSException exceptionWithName:@"InvalidInput"
                                 reason:[NSString stringWithFormat:@"Invalid type of value for key %@.", key]
                               userInfo:nil] raise];
        continue;
      }

      if (numberVal.doubleValue == 0) {
        continue;
      }

      NSInteger h = (int32_t)[IMPMurmurHash hash32:key];

      if (self.shouldAlternateSign && h < 0) {
        numberVal = @(-numberVal.doubleValue);
      }

      NSInteger index = abs(h) % self.numberOfFeatures;
      NSNumber *currentVal = row[index];
      row[index] = @(currentVal.doubleValue + numberVal.doubleValue);
    }

    [output addObject:row];
  }
  
  return [output copy];
}

@end
