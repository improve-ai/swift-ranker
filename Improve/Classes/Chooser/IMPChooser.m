//
//  IMPChooser.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import "IMPChooser.h"
#import "IMPFeatureHasher.h"
#import "IMPEncodedFeatureProvider.h"
#import "NSArray+Random.h"
#import "IMPCommon.h"
#import "IMPScoredObject.h"
#import "IMPModelBundle.h"
#import "IMPModelMetadata.h"


const NSUInteger kInitialTrialsCount = 100;


@implementation IMPChooser

+ (instancetype)chooserWithModelBundle:(IMPModelBundle *)bundle
                             namespace:(NSString *)namespace
                                 error:(NSError *__autoreleasing  _Nullable *)error
{
    if (!namespace) {
        return nil;
    }
    MLModel *model = [MLModel modelWithContentsOfURL:bundle.compiledModelURL error:error];
    if (!model) {
        return nil;
    }
    IMPModelMetadata *metadata = [IMPModelMetadata metadataWithURL:bundle.metadataURL];
    if (!metadata) {
        return nil;
    }
    return [[self alloc] initWithModel:model metadata:metadata namespace:namespace];
}

- (instancetype)initWithModel:(MLModel *)model metadata:(IMPModelMetadata *)metadata namespace:(NSString *)namespace
{
    self = [super init];
    if (self) {
        _model = model;
        _metadata = metadata;
        _namespace = namespace;
        _featureNamePrefix = @"f";
    }
    return self;
}

- (NSUInteger)numberOfFeatures {
    return self.metadata.numberOfFeatures;
}

#pragma mark Predicting

/**
@returns Returns an array of NSNumber (double) objects.
*/
- (NSArray *)batchPrediction:(NSArray<NSDictionary<NSNumber*,id>*> *)batchFeatures
{
    MLArrayBatchProvider *batchProvider = [self batchProviderForFeaturesArray:batchFeatures];

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
        [output addObject:@(sigmfix(val))];
    }
    return output;
}


- (MLArrayBatchProvider* )
batchProviderForFeaturesArray:(NSArray<NSDictionary<NSNumber*,id>*> *)batchFeatures
{
    NSMutableArray *featureProviders = [NSMutableArray arrayWithCapacity:batchFeatures.count];
    for (NSDictionary<NSNumber*,id> *features in batchFeatures)
    {
        id<MLFeatureProvider> provider = [[IMPEncodedFeatureProvider alloc] initWithDictionary:features prefix:self.featureNamePrefix count:self.metadata.numberOfFeatures];
        [featureProviders addObject:provider];
    }
    return [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:featureProviders];
}

#pragma mark Feature Extracting


#pragma mark Choosing

- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
{
    return [[self sort:variants context:context] objectAtIndex:0];
}


- (NSArray<NSDictionary*> *)makeFeaturesFromTrials:(NSArray *) trials
                                       withContext:(NSDictionary *)context
{
    NSDictionary *namespacedContext = @{ @"context": @{ _namespace: context }};
    
    NSMutableArray<NSDictionary*> *features = [NSMutableArray arrayWithCapacity:trials.count];
    for (NSDictionary *trial in trials) {
        NSMutableDictionary *total = [namespacedContext mutableCopy];
        [total addEntriesFromDictionary:@{ @"variant": @{ _namespace: trial }}];
        [features addObject:total];
    }

    return features;
}

#pragma mark - Ranking

- (NSArray *) sort:(NSArray *)variants
           context:(NSDictionary *)context
{
    NSArray *features = [self makeFeaturesFromTrials:variants
                                         withContext:context];
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    NSArray *encodedFeatures = [hasher batchEncode:features];
    NSArray *scores = [self batchPrediction:encodedFeatures];
    if (!scores) { return nil; }

    NSUInteger count = scores.count;
    NSMutableArray *scoredVariants = [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++)
    {
        double score = [scores[i] doubleValue];
        NSDictionary *variant = variants[i];
        id scored = [IMPScoredObject withScore:score object:variant];
        [scoredVariants addObject:scored];
    }

    [scoredVariants sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];

    NSMutableArray *outputVariants = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++)
    {
        IMPScoredObject *scored = scoredVariants[i];
        [outputVariants addObject:scored.object];
    }

    return outputVariants;
}

@end
