//
//  IMPChooser.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import "IMPChooser.h"
#import "IMPFeatureEncoder.h"
#import "NSDictionary+MLFeatureProvider.h"
#import "NSArray+Random.h"
#import "IMPCommon.h"
#import "IMPModelMetadata.h"
#import "IMPLogging.h"
#import "IMPJSONUtils.h"

@implementation IMPChooser

- (instancetype)initWithModel:(MLModel *)model metadata:(IMPModelMetadata *)metadata
{
    self = [super init];
    if (self) {
        _model = model;
        _metadata = metadata;
        _featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:metadata.seed];
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
- (NSArray *)batchPrediction:(NSArray<NSDictionary *> *)batchFeatures
{
    MLArrayBatchProvider *batchProvider = [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:batchFeatures];

    NSError *error = nil;
    id<MLBatchProvider> prediction
    = [self.model predictionsFromBatch:batchProvider
                               options:[MLPredictionOptions new]
                                 error:&error];
    if (!prediction) {
        IMPErrLog("predictionsFromBatch error: %@", error);
        return nil;
    }

    NSMutableArray *output = [NSMutableArray arrayWithCapacity:prediction.count];
    for (NSUInteger i = 0; i < prediction.count; i++) {
        double val = [[prediction featuresAtIndex:i] featureValueForName:@"target"].doubleValue;
        [output addObject:@(val)];
    }
    return output;
}

#pragma mark Choosing

- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
{
    NSArray *encodedFeatures = [self encodeVariants:variants withContext:context];

    NSArray *scores = [self batchPrediction:encodedFeatures];
    if (!scores) {
        IMPErrLog("Choose failed because batch prediction failed. Returning nil.");
        return nil;
    }

#ifdef IMP_DEBUG
    // Print out variant, encoded variant and score, sorted by score
    NSMutableArray *debugVariants = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSInteger i = 0; i < variants.count; i++)
    {
        NSDictionary *debugVariant = @{
            @"variant": variants[i],
            @"encodedVariant": encodedFeatures[i],
            @"score": scores[i]
        };
        [debugVariants addObject:debugVariant];
    }
    [debugVariants sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];
    for (NSInteger i = 0; i < debugVariants.count; i++)
    {
        NSDictionary *debugVariant = debugVariants[i];
        NSString *variantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:debugVariant[@"variant"]];
        NSString *encodedVariantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:debugVariant[@"encodedVariant"]];
        IMPLog("#%ld score: %@ variant: %@ encoded: %@", i, debugVariant[@"score"], variantJson, encodedVariantJson);
    }
#endif

    id best = [self bestSampleFrom:variants forScores:scores];
    return best;
}

- (NSArray<NSDictionary *> *)encodeVariants:(NSArray<NSDictionary*> *)variants
                                   withContext:(nullable NSDictionary *)context
{
    if (!context) {
        // Safe nil context handling
        context = @{};
    }
    IMPLog("Context: %@", context);
    double noise = ((double)arc4random() / UINT32_MAX); // between 0.0 and 1.0
    NSDictionary *contextFeatures = [_featureEncoder encodeContext:context withNoise:noise];
    IMPLog("Encoded context: %@", contextFeatures);
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSDictionary *variant in variants) {
        NSMutableDictionary *variantFeatures = [contextFeatures mutableCopy];
        // TODO set feature names NSSet on variantFeatures
        [result addObject:[_featureEncoder encodeVariant:variant withNoise:noise forFeatures:variantFeatures]];
    }
    return result;
}

/// Performs reservoir sampling to break ties when variants have the same score.
- (nullable id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores
{
    double bestScore = -DBL_MAX;
    id bestVariant = nil;
    NSInteger replacementCount = 0;
    for (NSInteger i = 0; i < scores.count; i++)
    {
        double score = [scores[i] doubleValue];
        if (score > bestScore)
        {
            bestScore = score;
            bestVariant = variants[i];
            replacementCount = 0;
        }
        else if (score == bestScore)
        {
            double replacementProbability = 1.0 / (double)(2 + replacementCount);
            replacementCount++;
            if (drand48() <= replacementProbability) {
                bestScore = score;
                bestVariant = variants[i];
            }
        }
    }

    return bestVariant;
}

#pragma mark - Ranking

- (NSArray *) sort:(NSArray *)variants
           context:(NSDictionary *)context
{
    NSArray *shuffledVariants = [variants shuffledArray];
    NSArray *encodedFeatures = [self encodeVariants:shuffledVariants withContext:context];
    NSArray *scores = [self batchPrediction:encodedFeatures];
    if (!scores) { return nil; }

    NSUInteger count = scores.count;
    NSMutableArray *scoredVariants = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++)
    {
        NSDictionary *scoredVariant = @{
            @"variant": shuffledVariants[i],
#ifdef IMP_DEBUG
            @"encodedVariant": encodedFeatures[i],
#endif
            @"score": scores[i]
        };
        [scoredVariants addObject:scoredVariant];
    }

    [scoredVariants sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];

#ifdef IMP_DEBUG
    for (NSInteger i = 0; i < scoredVariants.count; i++)
    {
        NSDictionary *variant = scoredVariants[i];
        NSString *variantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:variant[@"variant"]];
        NSString *encodedVariantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:variant[@"encodedVariant"]];
        IMPLog("#%ld score: %@ variant: %@ encoded: %@", i, variant[@"score"], variantJson, encodedVariantJson);
    }
#endif

    NSMutableArray *outputVariants = [NSMutableArray arrayWithCapacity:count];
    for (NSUInteger i = 0; i < count; i++)
    {
        NSDictionary *scoredVariant = scoredVariants[i];
        [outputVariants addObject:scoredVariant[@"variant"]];
    }

    return outputVariants;
}

- (NSArray *)score:(NSArray *)variants
           context:(NSDictionary *)context
{
    NSArray *encodedFeatures = [self encodeVariants:variants withContext:context];
    NSArray *scores = [self batchPrediction:encodedFeatures];
    return scores;
}

@end
