//
//  IMPChooser.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import "IMPChooser.h"
#import "IMPFeatureHasher.h"
#import "MLDictionaryFeatureProvider+Utils.h"
#import "NSArray+Random.h"
#import "IMPCommon.h"
#import "IMPScoredObject.h"
#import "IMPModelBundle.h"
#import "IMPModelMetadata.h"


const NSUInteger kInitialTrialsCount = 100;

NSString *const kFeatureNamePrefix = @"f";

@implementation IMPChooser

+ (instancetype)chooserWithModelBundle:(IMPModelBundle *)bundle
                                 error:(NSError *__autoreleasing  _Nullable *)error
{
    MLModel *model = [MLModel modelWithContentsOfURL:bundle.modelURL error:error];
    if (!model) {
        return nil;
    }
    IMPModelMetadata *metadata = [IMPModelMetadata metadataWithURL:bundle.metadataURL];
    if (!metadata) {
        return nil;
    }
    return [[self alloc] initWithModel:model metadata:metadata];
}

- (instancetype)initWithModel:(MLModel *)model metadata:(IMPModelMetadata *)metadata
{
    self = [super init];
    if (self) {
        _model = model;
        _metadata = metadata;
    }
    return self;
}

- (NSString *)hashPrefix {
    return self.metadata.hashPrefix;
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

/// Returns prediction for the given row or -1 if error.
- (double)singleRowPrediction:(NSDictionary<NSNumber*,id> *)features
{
    NSError *error = nil;
    MLDictionaryFeatureProvider *featureProvider
    = [[MLDictionaryFeatureProvider alloc] initWithDictionary:features prefix:kFeatureNamePrefix error:&error];
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
    return sigmfix(output);
}

- (MLArrayBatchProvider* )
batchProviderForFeaturesArray:(NSArray<NSDictionary<NSNumber*,id>*> *)batchFeatures
{
    NSMutableArray *featureProviders = [NSMutableArray arrayWithCapacity:batchFeatures.count];
    for (NSDictionary<NSNumber*,id> *features in batchFeatures)
    {
        NSError *error;
        MLDictionaryFeatureProvider *provider = [[MLDictionaryFeatureProvider alloc] initWithDictionary:features prefix:kFeatureNamePrefix error:&error];
        if (!provider) return nil;
        [featureProviders addObject:provider];
    }
    return [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:featureProviders];
}

#pragma mark Choosing

- (NSDictionary *)choose:(NSDictionary *)variants
                 context:(NSDictionary *)context
{
    NSArray<NSDictionary*> *trials = [self randomTrials:variants count:kInitialTrialsCount];

    NSDictionary *bestTrial = nil;
    double bestScore = 0;
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    while (YES)
    {
        NSArray *features = [self makeFeaturesFromTrials:trials
                                             withContext:context
                                              hashPrefix:self.hashPrefix];
        NSArray *encodedFeatures = [self batchEncode:features withEncoder:hasher];
        NSArray *scores = [self batchPrediction:encodedFeatures];
        if (!scores) { return nil; }
        NSLog(@"Scores: %@", scores);//test
        NSUInteger maxScoreIdx = 0;
        for (NSUInteger i = 1; i < scores.count; i++)
        {
            if ([scores[i] doubleValue] > [scores[maxScoreIdx] doubleValue]) {
                maxScoreIdx = i;
            }
        }

        double maxScore = [scores[maxScoreIdx] doubleValue];

        if (!bestTrial || maxScore > bestScore) {
            bestTrial = trials[maxScoreIdx];
            bestScore = maxScore;
            trials = [self adjacentTrials:bestTrial variants:variants];
        } else {
            break;
        }
    }

    return bestTrial;
}


- (NSArray<NSDictionary*> *)randomTrials:(NSDictionary *)variants
                                   count:(NSUInteger)count
{
    NSMutableArray *trials = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger n = 0; n < count; n++)
    {
        NSMutableDictionary *trial = [NSMutableDictionary new];
        for (NSString *key in variants)
        {
            NSArray *array = INSURE_CLASS(variants[key], [NSArray class]);
            if (!array) { continue; }

            trial[key] = array.randomObject;
        }
        [trials addObject:trial];
    }

    return trials;
}

- (NSArray<NSDictionary*> *)makeFeaturesFromTrials:(NSArray<NSDictionary*> *)trials
                                       withContext:(NSDictionary *)context
                                        hashPrefix:(NSString *)prefix
{
    NSMutableArray<NSDictionary*> *features = [NSMutableArray arrayWithCapacity:trials.count];
    for (NSDictionary *trial in trials) {
        NSMutableDictionary *total = [context mutableCopy];

        [total addEntriesFromDictionary:trial];
    }

    return features;
}

- (NSArray<NSDictionary<NSNumber*,id>*> *)batchEncode:(NSArray<NSDictionary*> *)rawFeatures withEncoder:(IMPFeatureHasher *)encoder
{
    NSMutableArray *batchEncoded = [NSMutableArray arrayWithCapacity:rawFeatures.count];
    for (NSDictionary *featuresDict in rawFeatures) {
        [batchEncoded addObject:[encoder encodeFeatures:featuresDict]];
    }

    return batchEncoded;
}

/// Creates an array of slightly different trials, replacing one key in each adjacent trial by a random variant.
- (NSArray<NSDictionary*> *)adjacentTrials:(NSDictionary *)trial
                                  variants:(NSDictionary *)variants
{
    NSMutableArray *adjacents = [NSMutableArray new];

    for (NSString *key in variants)
    {
        NSArray *variantsList = INSURE_CLASS(variants[key], [NSArray class]);
        if (!variantsList) { continue; }

        for (id variant in variantsList) {
            NSMutableDictionary *adjacentTrial = [trial mutableCopy];
            adjacentTrial[key] = variant;
            [adjacents addObject:adjacentTrial];
        }
    }

    return adjacents;
}

#pragma mark - Ranking

- (NSArray<NSDictionary*> *)rank:(NSArray<NSDictionary*> *)variants
                         context:(NSDictionary *)context
{
    NSArray *features = [self makeFeaturesFromTrials:variants
                                         withContext:context
                                          hashPrefix:self.hashPrefix];
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    NSArray *encodedFeatures = [self batchEncode:features withEncoder:hasher];
    NSArray *scores = [self batchPrediction:encodedFeatures];
    if (!scores) { return nil; }
    NSLog(@"%@", scores);

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
