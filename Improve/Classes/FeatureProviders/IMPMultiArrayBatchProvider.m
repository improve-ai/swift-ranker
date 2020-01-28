//
//  IMPMultiArrayBatchProvider.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/27/20.
//

#import "IMPMultiArrayBatchProvider.h"
#import "IMPMultiArrayFeatureProvider.h"

@implementation IMPMultiArrayBatchProvider

- (instancetype)initWithArray:(MLMultiArray *)multiArray {
  assert(multiArray.shape.count == 2);
  
  self = [super init];
  if (self) {
    _multiArray = multiArray;
  }
  return self;
}

- (NSInteger)count {
  // Rows count
  return [self.multiArray.shape[0] integerValue];
}

- (nonnull id<MLFeatureProvider>)featuresAtIndex:(NSInteger)index
{
  IMPMultiArrayFeatureProvider *rowFeatureProvider
  = [[IMPMultiArrayFeatureProvider alloc] initWithArray:self.multiArray rowIndex:index];
  return rowFeatureProvider;
}

@end
