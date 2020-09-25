//
//  Improve.m
//  7Second
//
//  Created by Choosy McChooseFace on 9/6/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModel.h"
#import "IMPChooser.h"
#import "IMPTracker.h"
#import "NSArray+Random.h"
#import "IMPLogging.h"
#import "Constants.h"
#import "IMPJSONUtils.h"
#import "IMPModelMetadata.h"

@interface IMPModel ()
// Private vars

@property (strong, atomic) IMPChooser *chooser;
@property (strong, atomic) IMPTracker *tracker;

@end


@implementation IMPModel


+ (void)modelWithContentsOfURL:(NSURL *)url
            configuration:(IMPModelConfiguration *)configuration
        completionHandler:(void (^)(IMPModel *model, NSError *error))handler
{
    
}

- (instancetype) initWithMLModel:(MLModel *) mlModel configuration:(IMPModelConfiguration *)configuration;
{
    self = [super init];
    if (!self) return nil;

    self.mlModel = mlModel; // call self to get metadata and chooser
    if (configuration) {
        self.configuration = configuration;
    }
    
    return self;
}

- (void) setMlModel:(MLModel *)mlModel
{
    _mlModel = mlModel;
    
    
    NSString *jsonMetadata = mlModel.modelDescription.metadata[@"json"];

    NSError *error;
    
    NSDictionary *json = [IMPJSONUtils objectFromString:jsonMetadata];
    if (!json) {
        IMPErrLog("Json parse error: %@", error);
        return;
    }
    
    IMPModelMetadata *metadata = [[IMPModelMetadata alloc] initWithDict:json];
    if (!metadata) {
        return;
    }
    
    _modelName = metadata.model;

    _chooser = [[IMPChooser alloc] initWithModel:mlModel metadata:metadata];
    if (!_chooser) {
        IMPErrLog("Failed to initialize Chooser: %@", error);
    }

}

- (MLModel *)mlModel
{
    return _mlModel;
}

- (void) setConfiguration:(IMPModelConfiguration *)configuration
{
    _configuration = configuration;
    if (configuration) {
        _tracker = [[IMPTracker alloc] initWithConfiguration:configuration];
    }
}

- (id) choose:(NSArray *) variants
{
    return [self choose:variants context:nil];
}

- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context
{
    if (!variants || [variants count] == 0) {
        IMPErrLog("Non-nil, non-empty array required for choose variants. returning nil.");
        return nil;
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kChooseMethod,
            kVariantsKey: variants
        }];
    }

    id chosen;

    IMPChooser *chooser = [self chooser];
    if (chooser) {
        chosen = [chooser choose:variants context:context];
        [self calculateAndTrackPropensityOfChosen:chosen
                                    amongVariants:variants
                                        inContext:context
                                      withChooser:chooser
                                       chooseDate:[NSDate date]];
    } else {
        IMPErrLog("Model not loaded.");
    }
    
    if (!chosen) {
        IMPErrLog("Choosing first variant.");
        return [variants objectAtIndex:0];
    }

    return chosen;
}


- (NSArray *) sort:(NSArray *) variants
{
    return [self sort:variants context:nil];
}

- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context
{
    if (!variants || [variants count] == 0) {
        IMPErrLog("Non-nil, non-empty array required for sort variants. returning empty array");
        return @[];
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kSortMethod,
            kVariantsKey: variants
        }];
    }
    
    NSArray *sorted;

    IMPChooser *chooser = [self chooser];
    if (chooser) {
        sorted = [chooser sort:variants context:context];
    } else {
        IMPErrLog("Model not loaded.");
    }
    
    if (!sorted) {
        IMPErrLog("Returning unsorted shallow copy of variants.");
        return [[NSArray alloc] initWithArray:variants];
    }

    return sorted;
}

- (void) trackDecision:(id) variant
{
    [self trackDecision:variant context:nil rewardKey:nil];
}

- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
{
    [self trackDecision:variant context:context rewardKey:nil];
}

- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey
{
    if (self.tracker) {
        [self.tracker trackDecision:variant
                    context:context
                  rewardKey:rewardKey
                 completion:nil];
    } else {
        IMPErrLog("Attempted to call trackDecision with null tracker");
    }
}

- (void) addReward:(NSNumber *) reward
{
    [self addReward:reward forKey:self.modelName];
}

- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey
{
    if (self.tracker) {
        [self.tracker addReward:reward forKey:rewardKey completion:nil];
    } else {
        IMPErrLog("Attempted to call addReward with null tracker");
    }
}

- (void) addRewards:(NSDictionary *)rewards
{
    if (self.tracker) {
        [self.tracker addRewards:rewards completion:nil];
    } else {
        IMPErrLog("Attempted to call addRewards with null tracker");
    }
}

@end
