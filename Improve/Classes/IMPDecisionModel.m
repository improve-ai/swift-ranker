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
#import "IMPChooser.h"
#import "IMPModelDownloader.h"


@interface IMPDecisionModel ()
// Private vars

@property (strong, atomic) IMPChooser *chooser;

@end

 
@implementation IMPDecisionModel

@synthesize model = _model;

+ (void)modelWithContentsOfURL:(NSURL *)url
                   cacheMaxAge:(NSInteger) cacheMaxAge
             completionHandler:(IMPDecisionModelDownloadCompletion)handler
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
    self = [super init];
    if (!self) return nil;

    self.model = model; // call setter to set up metadata and chooser

    return self;
}

- (MLModel *) model
{
    @synchronized (self) {
        return _model;
    }
}

- (void) setModel:(MLModel *)model
{
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

        _name = metadata.model;

        _chooser = [[IMPChooser alloc] initWithModel:model metadata:metadata];
        if (!_chooser) {
            IMPErrLog("Failed to initialize Chooser!");
        }
    }
}

- (NSArray *)score:(NSArray *)variants
{
    return [self score:variants context:nil];
}

- (NSArray *) score:(NSArray *)variants
              given:(NSDictionary *)context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. Returning empty array");
            return @[];
        }

        IMPChooser *chooser = [self chooser];
        if (chooser) {
            return [chooser score:variants context:context];
        } else {
            IMPErrLog("Model not loaded. Returning empty array");
            return @[];
        }
    }
}


+ (NSArray *)rankScoredVariants:(NSArray *)scored
{
    NSArray *shuffled = [scored shuffledArray];
    NSArray *sorted = [shuffled sortedArrayUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];
    NSArray *variants = [sorted valueForKeyPath: @"@unionOfObjects.variant"];
    return variants;
}

/// Performs reservoir sampling to break ties when variants have the same score
+ (nullable id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores
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

@end
