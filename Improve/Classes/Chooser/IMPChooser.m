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

#pragma mark Predicting


- (NSArray <NSNumber *>*) score:(NSArray *)variants
                          given:(nullable NSDictionary <NSString *, id>*)context
{
    NSArray *encodedFeatures = [self encodeVariants:variants withContext:context];
    
    MLArrayBatchProvider *batchProvider = [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:encodedFeatures];

    NSError *error = nil;
    id<MLBatchProvider> prediction = [self.model predictionsFromBatch:batchProvider
                                                              options:[MLPredictionOptions new]
                                                                error:&error];
    if (!prediction) {
        IMPErrLog("predictionsFromBatch error: %@", error);
        return nil;
    }

    NSMutableArray *scores = [NSMutableArray arrayWithCapacity:prediction.count];
    for (NSUInteger i = 0; i < prediction.count; i++) {
        double val = [[prediction featuresAtIndex:i] featureValueForName:@"target"].doubleValue;
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


@end
