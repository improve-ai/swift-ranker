//
//  IMPChooser.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import "IMPChooser.h"
#import "MLDictionaryFeatureProvider+NSArray.h"
#import "IMPMultiArrayBatchProvider.h"

@implementation IMPChooser

+ (instancetype)chooserWithModelURL:(NSURL *)modelURL error:(NSError **)error
{
  MLModel *m = [MLModel modelWithContentsOfURL:modelURL error:error];
  if (!m) {
    return nil;
  }
  return [[self alloc] initWithModel:m];
}

- (instancetype)initWithModel:(MLModel *)model
{
  self = [super init];
  if (self) {
    _model = model;
  }
  return self;
}

- (NSArray *)predicitonForArray:(MLMultiArray *)array
{
  IMPMultiArrayBatchProvider *batchProvider
  = [[IMPMultiArrayBatchProvider alloc] initWithArray:array];

  NSError *error = nil;
  id<MLBatchProvider> prediction
  = [self.model predictionsFromBatch:batchProvider error:&error];
  if (!prediction) {
    NSLog(@"predictionsFromBatch error: %@", error);
    return nil;
  }

  NSMutableArray *output = [NSMutableArray arrayWithCapacity:prediction.count];
  for (NSUInteger i = 0; i < prediction.count; i++) {
    double val = [[prediction featuresAtIndex:i] featureValueForName:@"target"].doubleValue;
    [output addObject:@(val)];
  }
  return output;
}

- (double)singleRowPrediction:(NSArray *)features
{
  NSError *error = nil;
  MLDictionaryFeatureProvider *featureProvider
  = [[MLDictionaryFeatureProvider alloc] initWithArray:features prefix:@"f" error:&error];
  if (!featureProvider) {
    NSLog(@"MLDictionaryFeatureProvider error: %@", error);
    return -1;
  }

  id<MLFeatureProvider> prediction
  = [self.model predictionFromFeatures:featureProvider error:&error];
  if (!prediction) {
    NSLog(@"predictionFromFeatures error: %@", error);
    return -1;
  }

  double output = [[prediction featureValueForName:@"target"] doubleValue];
  return output;
}

@end
