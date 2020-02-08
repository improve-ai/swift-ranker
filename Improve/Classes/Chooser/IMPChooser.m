//
//  IMPChooser.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import "IMPChooser.h"
#import "IMPFeatureHasher.h"
#import "MLDictionaryFeatureProvider+NSArray.h"
#import "IMPMatrix.h"
#import "IMPMatrixBatchProvider.h"
#import "NSArray+Random.h"
#import "IMPCommon.h"
#import "IMPJSONUtils.h"


const NSUInteger kInitialTrialsCount = 100;


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

#pragma mark Predicting

- (NSArray *)batchPrediction:(IMPMatrix *)matrix
{
    IMPMatrixBatchProvider *batchProvider
    = [[IMPMatrixBatchProvider alloc] initWithMatrix:matrix];

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
    return sigmfix(output);
}

#pragma mark Choosing

- (NSDictionary *)choose:(NSDictionary *)variants
                 context:(NSDictionary *)context
{
    NSArray<NSDictionary*> *trials = [self randomTrials:variants count:kInitialTrialsCount];

    NSDictionary *bestTrial = nil;
    double bestScore = 0;
    // TODO: inject number of features
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithNumberOfFeatures:10000];
    while (YES)
    {
        NSArray *features = [self makeFeaturesFromTrials:trials
                                             withContext:context
                                              hashPrefix:self.hashPrefix];
        IMPMatrix *hashMatrix = [hasher transform:features];
        NSArray *scores = [self batchPrediction:hashMatrix];
        if (!scores) { return nil; }
        
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
        
        [features addObject:[IMPJSONUtils propertiesToFeatures:total withPrefix:prefix]];
    }

    return features;
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

@end
