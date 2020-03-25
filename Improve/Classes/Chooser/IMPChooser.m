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
#import "IMPFeaturesMap.h"


const NSUInteger kInitialTrialsCount = 100;


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

/// Returns prediction for the given row or -1 if error.
- (double)singleRowPrediction:(NSDictionary<NSNumber*,id> *)features
{
    id<MLFeatureProvider> featureProvider
    = [[IMPEncodedFeatureProvider alloc] initWithDictionary:features prefix:self.featureNamePrefix count:self.metadata.numberOfFeatures];

    NSError *error;
    id<MLFeatureProvider> prediction
    = [self.model predictionFromFeatures:featureProvider error:&error];
    if (!prediction) {
        NSLog(@"predictionFromFeatures error: %@", error);
        return -1;
    }

    double output = [[prediction featureValueForName:@"target"] doubleValue];
    NSLog(@"target: %f", output);
    return sigmfix(output);
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

/**
 @param variantsMap A dictionary of arrays.
 */
- (IMPFeaturesMap *)partialTrialsFeaturesMapWithContext:(NSDictionary *)context
                                               variants:(NSDictionary *)variantsMap
{
    IMPFeatureHasher *encoder = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];

    IMPFeaturesMap *map = [IMPFeaturesMap new];
    map.context = context;
    map.contextFeatures = [encoder encodeFeatures:context];

    NSMutableDictionary *partialTrials = [NSMutableDictionary dictionaryWithCapacity:variantsMap.count];
    NSMutableDictionary *partialFeatures = [NSMutableDictionary dictionaryWithCapacity:variantsMap.count];
    for (NSString *propertyKey in variantsMap)
    {
        NSArray *variants = variantsMap[propertyKey];
        NSMutableArray *trialsForKey = [NSMutableArray arrayWithCapacity:variants.count];
        NSMutableArray *featuresForKey = [NSMutableArray arrayWithCapacity:variants.count];
        partialTrials[propertyKey] = trialsForKey;
        partialFeatures[propertyKey] = featuresForKey;

        for (id variant in variants) {
            [trialsForKey addObject:@{propertyKey: variant}];
            [featuresForKey addObject:
             [encoder encodePartialFeaturesWithKey:propertyKey
                                           variant:variant]
             ];
        }
    }
    map.partialTrials = partialTrials;
    map.partialFeatures = partialFeatures;

    return map;
}

#pragma mark Choosing

- (NSDictionary *)choose:(NSDictionary *)variants
                 context:(NSDictionary *)context
{
    IMPFeaturesMap *featuresMap = [self partialTrialsFeaturesMapWithContext:context
                                                                   variants:variants];

    /* Trial is dictionary of integers where key is a propertyKey from `variants`
     and value is index of the variant in array. */
    NSArray<NSDictionary*> *trials;
    NSArray<NSDictionary<NSNumber*, NSNumber*> *> *featurizedTrials;
    [self getRandomTrials:&trials
         featurizedTrials:&featurizedTrials
          fromFeaturesMap:featuresMap
                    count:kInitialTrialsCount];
    NSLog(@"trials: %@", trials);
NSLog(@"featurizedTrials: %@", featurizedTrials);

    NSDictionary *bestTrial = nil;
    double bestScore = 0;
    while (YES)
    {
        NSArray *scores = [self batchPrediction:featurizedTrials];
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

            [self getAdjacentTrials:&trials
                         featurized:&featurizedTrials
                          fromTrial:bestTrial
                    featurizedTrial:featurizedTrials[maxScoreIdx]
                    withFeaturesMap:featuresMap];
        } else {
            break;
        }
    }

    return bestTrial;
}

/**
 @param trialsP Pointer to a variable which will be initialized with random trials [{key1: variant1A}, {key2, vriant2B}, ...]
 @param featurizedTrialsP Pointer to a variable which will be initialized with random trial
 features corresponding to `trialsP`. Contains values of type NSDictionary<NSNumber*, NSNumber*>.
 @param map A initialized features map.
 @param count How many trials do you need?
 */
- (void)getRandomTrials:(NSArray<NSDictionary*> **)trialsP
       featurizedTrials:(NSArray<NSDictionary*> **)featurizedTrialsP
        fromFeaturesMap:(IMPFeaturesMap *)map
                  count:(NSUInteger)count
{
    NSMutableArray *trials = [NSMutableArray arrayWithCapacity:count];
    NSMutableArray *featurizedTrials = [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger n = 0; n < count; n++)
    {
        NSMutableDictionary *trialProperties = [NSMutableDictionary dictionaryWithCapacity:map.partialTrials.count];
        [trials addObject:trialProperties];
        NSMutableDictionary *trialFeatures = [map.contextFeatures mutableCopy];
        [featurizedTrials addObject:trialFeatures];
        for (NSString *key in map.partialTrials)
        {
            NSArray *variants = map.partialTrials[key];
            NSArray *features = map.partialFeatures[key];
            uint32_t randomIndex = arc4random_uniform((uint32_t)variants.count);
            [trialProperties addEntriesFromDictionary:variants[randomIndex]];
            [trialFeatures addEntriesFromDictionary:features[randomIndex]];
        }
    }

    *trialsP = trials;
    *featurizedTrialsP = featurizedTrials;
}

- (NSArray<NSDictionary*> *)makeFeaturesFromTrials:(NSArray<NSDictionary*> *)trials
                                       withContext:(NSDictionary *)context
{
    NSMutableArray<NSDictionary*> *features = [NSMutableArray arrayWithCapacity:trials.count];
    for (NSDictionary *trial in trials) {
        NSMutableDictionary *total = [context mutableCopy];
        [total addEntriesFromDictionary:trial];
        [features addObject:total];
    }

    return features;
}

/// Creates an array of slightly different trials, replacing one key in each adjacent trial by a random variant.
- (void)getAdjacentTrials:(NSArray<NSDictionary*> **)trialsP
               featurized:(NSArray<NSDictionary*> **)featurizedTrialsP
                fromTrial:(NSDictionary *)trial
          featurizedTrial:(NSDictionary *)featurizedTrial
          withFeaturesMap:(IMPFeaturesMap *)map
{
    NSMutableArray *adjacentTrials = [NSMutableArray new];
    NSMutableArray *adjacentFeatures = [NSMutableArray new];

    for (NSString *key in map.partialTrials)
    {
        NSArray *variantsList = map.partialTrials[key];
        NSArray *featuresList = map.partialFeatures[key];

        for (NSUInteger i = 0; i < variantsList.count; i++) {
            NSMutableDictionary *adjacentTrial = [trial mutableCopy];
            [adjacentTrial addEntriesFromDictionary:variantsList[i]];
            [adjacentTrials addObject:adjacentTrial];

            NSMutableDictionary *adjacentFeaturized = [featurizedTrial mutableCopy];
            [adjacentFeaturized addEntriesFromDictionary:featuresList[i]];
            [adjacentFeatures addObject:adjacentFeaturized];
        }
    }

    *trialsP = adjacentTrials;
    *featurizedTrialsP = adjacentFeatures;
}

#pragma mark - Ranking

- (NSArray<NSDictionary*> *)rank:(NSArray<NSDictionary*> *)variants
                         context:(NSDictionary *)context
{
    NSArray *features = [self makeFeaturesFromTrials:variants
                                         withContext:context];
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    NSArray *encodedFeatures = [hasher batchEncode:features];
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
