//
//  IMPMultiArrayFeatureProvider.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/27/20.
//

#import "IMPMultiArrayFeatureProvider.h"

@implementation IMPMultiArrayFeatureProvider

- (instancetype)initWithArray:(MLMultiArray *)multiArray featuresRange:(NSRange)featuresRange
{
  assert(multiArray.shape.count == 2);

  self = [super init];
  if (!self) return self;

  _multiArray = multiArray;
  _featuresRange = featuresRange;
  _prefix = @"f";
  
  return self;
}

- (instancetype)initWithArray:(MLMultiArray *)multiArray rowIndex:(NSInteger)row
{
  assert(multiArray.shape.count == 2);

  NSInteger rowLength = [multiArray.shape[0] integerValue];
  NSRange range = NSMakeRange(row * rowLength, rowLength);

  return [self initWithArray:multiArray featuresRange:range];
}

- (NSSet<NSString *> *)featureNames
{
  NSInteger length = self.featuresRange.length;
  NSMutableSet *names = [NSMutableSet setWithCapacity:length];

  for (NSInteger i = 0; i < length; i++)
  {
    [names addObject:[NSString stringWithFormat:@"%@%ld", self.prefix, i]];
  }
  return names;
}

- (nullable MLFeatureValue *)featureValueForName:(nonnull NSString *)featureName
{
  NSInteger featureIndex = [[featureName substringFromIndex:self.prefix.length] integerValue];
  NSInteger arrayIndex = featureIndex + self.featuresRange.location;

  NSNumber *number = [self.multiArray objectAtIndexedSubscript:arrayIndex];
  MLFeatureValue *featureValue = [MLFeatureValue featureValueWithDouble:number.doubleValue];

  // test
  if (number.doubleValue != 0) {
    NSLog(@"fvfn %@=%f", featureName, number.doubleValue);
  }

  return featureValue;
}

@end
