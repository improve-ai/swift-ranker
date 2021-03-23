//
//  IMPDecisionModel.m
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionModel.h"
#import "NSArray+Random.h"
#import "IMPLogging.h"
#import "IMPModelMetadata.h"
#import "IMPFeatureEncoder.h"
#import "IMPModelDownloader.h"
#import "IMPDecision.h"
#import "NSDictionary+MLFeatureProvider.h"
#import "IMPUtils.h"

@interface IMPDecisionModel ()
// Private vars

@property (strong, atomic) IMPFeatureEncoder *featureEncoder;

@end

@implementation IMPDecisionModel

@synthesize model = _model;

+ (instancetype)load:(NSURL *)url
{
    return [self load:url cacheMaxAge:0];
}

+ (instancetype)load:(NSURL *)url cacheMaxAge:(NSInteger) cacheMaxAge
{
    // tried using dispatch_semaphore_create here, but it caused a deadlock,
    // as the completion handler is called in main thread which is already
    // blocked by dispatch_semaphore_wait.
    __block IMPDecisionModel *decisionModel = nil;
    __block BOOL finished = NO;
    [self loadAsync:url cacheMaxAge:cacheMaxAge completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
        decisionModel = compiledModel;
        finished = YES;
    }];
    
    while (!finished) {
        NSLog(@"%@, Runloop waiting......", [NSDate date]);
        BOOL result = [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        NSLog(@"%@, Runloop waiting......, %d", [NSDate date], result);
    }
    
    return decisionModel;
}

+ (void)loadAsync:(NSURL *)url completion:(IMPDecisionModelLoadCompletion)handler
{
    [self loadAsync:url cacheMaxAge:0 completion:handler];
}

+ (void)loadAsync:(NSURL *)url cacheMaxAge:(NSInteger) cacheMaxAge completion:(IMPDecisionModelLoadCompletion)handler
{
    [[[IMPModelDownloader alloc] initWithURL:url maxAge:cacheMaxAge] downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable downloadError) {

        dispatch_async(dispatch_get_main_queue(), ^{
            if (downloadError) {
                if (handler) handler(nil, downloadError);
                return;
            }

            NSError *modelError;
            MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&modelError];
            if (modelError) {
                handler(nil, modelError);
                return;
            }
            handler([[self alloc] initWithModel:model], nil);
        });
    }];
}

- (instancetype) initWithModel:(MLModel *) model
{
    if(self = [super init]){
        self.model = model;
    }
    return self;
}

- (MLModel *) model
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        return _model;
    }
}

- (void) setModel:(MLModel *)model
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        _model = model;

        if (!model || !model.modelDescription || !model.modelDescription.metadata) {
            IMPErrLog("Invalid Improve model. model metadata not found");
            return;

        }
        NSDictionary * creatorDefined = model.modelDescription.metadata[MLModelCreatorDefinedKey];
        NSString *jsonMetadata;

        if (creatorDefined) {
            jsonMetadata = creatorDefined[@"json"];
        }

        if (!jsonMetadata) {
            IMPErrLog("Invalid Improve model. 'json' attribute not found");
            return;
        }

        IMPModelMetadata *metadata = [[IMPModelMetadata alloc] initWithString:jsonMetadata];
        if (!metadata) {
            return;
        }

        _modelName = metadata.modelName;
        
        NSSet *featureNames = [[NSSet alloc] initWithArray:_model.modelDescription.inputDescriptionsByName.allKeys];

        _featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:metadata.seed andFeatureNames:featureNames];
    }
}

- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    return [[[IMPDecision alloc] initWithModel:self] chooseFrom:variants];
}

- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens
{
    return [[[IMPDecision alloc] initWithModel:self] given:givens];
}

- (NSArray <NSNumber *>*)score:(NSArray *)variants
{
    return [self score:variants given:nil];
}

- (NSArray <NSNumber *>*) score:(NSArray *)variants
              given:(nullable NSDictionary <NSString *, id>*)givens
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. Returning empty array");
            return @[];
        }

        NSArray *encodedFeatures = [_featureEncoder encodeVariants:variants given:givens];
        
        MLArrayBatchProvider *batchProvider = [self batchProviderForFeaturesArray:encodedFeatures];

        NSError *error = nil;
        id<MLBatchProvider> prediction = [self.model predictionsFromBatch:batchProvider
                                                                  options:[MLPredictionOptions new]
                                                                    error:&error];
        if (!prediction) {
            IMPErrLog("MLModel.predictionsFromBatch error: %@ returning variants scored in descending order", error);
            // assign gaussian scores for the variants in descending order
            return [IMPUtils generateDescendingGaussians:variants.count];
        }

        NSMutableArray *scores = [NSMutableArray arrayWithCapacity:prediction.count];
        for (NSUInteger i = 0; i < prediction.count; i++) {
            double val = [[prediction featuresAtIndex:i] featureValueForName:@"target"].doubleValue;
            val += ((double)arc4random() / UINT32_MAX) * pow(2, -17); // add a very small random number to randomly break ties
            [scores addObject:@(val)];
        }
        return scores;
            
        /*
        #ifdef IMP_DEBUG
            for (NSInteger i = 0; i < scoredVariants.count; i++)
            {
                NSDictionary *variant = scoredVariants[i];
                NSString *variantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:variant[@"variant"]];
                NSString *encodedVariantJson = [IMPJSONUtils jsonStringOrDerscriptionOf:variant[@"encodedVariant"]];
                IMPLog("#%ld score: %@ variant: %@ encoded: %@", i, variant[@"score"], variantJson, encodedVariantJson);
            }
        #endif
         */
    }
}

- (nullable MLArrayBatchProvider* )
batchProviderForFeaturesArray:(NSArray<NSDictionary<NSString *,NSNumber *> *> *)batchFeatures
{
    NSMutableArray *featureProviders = [NSMutableArray arrayWithCapacity:batchFeatures.count];
    for (NSDictionary<NSString *, id> *features in batchFeatures)
    {
        [featureProviders addObject:features];
    }
    return [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:featureProviders];
}

// in case of tie, the lowest index wins. Ties should be very rare due to small random noise added to scores
// in IMPChooser.score()
+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores
{
    double bestScore = -DBL_MAX;
    id bestVariant = nil;
    for (NSInteger i = 0; i < scores.count; i++) {
        double score = [scores[i] doubleValue];
        if (score > bestScore)
        {
            bestScore = score;
            bestVariant = variants[i];
        }
    }

    return bestVariant;
}

+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores
{
    [NSException raise:@"TODO" format:@"TODO"];
    return nil;
}

@end
