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

- (MLMultiArray *)transform:(NSArray<NSDictionary<NSString*,id>*> *)x {
  // 2D Matrix of size numberOfSamples x numberOfFeatures
  NSError *err = nil;
  MLMultiArray *output = [[MLMultiArray alloc]
                          initWithShape:@[@(x.count), @(self.numberOfFeatures)]
                          dataType:MLMultiArrayDataTypeDouble
                          error:&err];
  for (NSInteger i = 0; i < x.count * self.numberOfFeatures; i++) {
    [output setObject:[NSNumber numberWithDouble:0] atIndexedSubscript:i];
  }

  if (!output) {
    NSLog(@"%@", err);
    return nil;
  }

  for (NSInteger row = 0; row < x.count; row++) {
    NSDictionary *sample = x[row];

    for (__strong NSString *key in sample) {
      id objectVal = sample[key];
      NSNumber *numberVal;
      if ([objectVal isKindOfClass:[NSString class]]) {
        key = [NSString stringWithFormat:@"%@=%@", key, objectVal];
        numberVal = [NSNumber numberWithInt:1];
      } else if ([objectVal isKindOfClass:[NSNumber class]]) {
        numberVal = objectVal;
      } else {
        NSString *reason = [NSString stringWithFormat:@"Invalid type of value (%@) for key %@.", objectVal, key];
        [[NSException exceptionWithName:@"InvalidInput"
                                 reason:reason
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
      NSArray *subscript = @[@(row), @(index)];
      NSNumber *currentVal = [output objectForKeyedSubscript:subscript];
      [output setObject:@(currentVal.doubleValue + numberVal.doubleValue)
      forKeyedSubscript:subscript];
    }
  }
  
  return output;
}

@end
