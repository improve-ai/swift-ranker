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
#import "IMPLogging.h"


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
- (NSArray *)batchPrediction:(NSArray<IMPFeaturesDictT*> *)batchFeatures
{
    MLArrayBatchProvider *batchProvider = [self batchProviderForFeaturesArray:batchFeatures];

    NSError *error = nil;
    id<MLBatchProvider> prediction
    = [self.model predictionsFromBatch:batchProvider error:&error];
    if (!prediction) {
        IMPErrLog("predictionsFromBatch error: %@", error);
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

#pragma mark Choosing

- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
{
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    if (!context) {
        // Safe nil context handling
        context = @{};
    }
    IMPLog("Starting choose...");
    IMPLog("Context: %@", context);
    IMPFeaturesDictT *encodedContext = [hasher encodeFeatures:@{
        @"context": @{ self.namespace: context }
    }];
    IMPLog("Encoded context: %@", encodedContext);
    IMPLog("Encoding variants... Count: %ld", variants.count);
    NSMutableArray *encodedFeatures = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSDictionary *variant in variants) {
        NSDictionary *namespaced = @{ @"variant": @{ self.namespace: variant }};
        [encodedFeatures addObject:[hasher encodeFeatures:namespaced
                                                startWith:encodedContext]];
    }

    IMPLog("Calculating scores...");
    NSArray *scores = [self batchPrediction:encodedFeatures];
    if (!scores) {
        IMPLog("Choosig failed because batch prediction failed. Returning nil.");
        return nil;
    }

#ifdef IMP_DEBUG
    // Print out variant, encoded variant and score, sorted by score
    IMPLog("Printing out scored variants...");
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
        IMPLog("#%ld\nVariant: %@\nEncoded variant: %@\nScore: %@", i, debugVariant[@"variant"], debugVariant[@"encodedVariant"], debugVariant[@"score"]);
    }
#endif

    return [self bestSampleFrom:variants forScores:scores];
}

- (NSArray<IMPFeaturesDictT*> *)encodeVariants:(NSArray<NSDictionary*> *)variants
                                   withContext:(NSDictionary *)context
{
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:self.metadata];
    IMPFeaturesDictT *encodedContext = [hasher encodeFeatures:@{
        @"context": @{self.namespace: context}
    }];
    NSMutableArray *encodedFeatures = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSDictionary *variant in variants) {
        NSDictionary *namespaced = @{@"variant": @{self.namespace: variant}};
        [encodedFeatures addObject:[hasher encodeFeatures:namespaced
                                                startWith:encodedContext]];
    }
    return encodedFeatures;
}

/// Performs reservoir sampling to break ties when variants have the same score.
- (id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores
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
        double score = [scores[i] doubleValue];
        NSDictionary *variant = shuffledVariants[i];
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
