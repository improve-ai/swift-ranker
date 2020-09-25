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
#import "IMPJSONUtils.h"
#import "IMPModelMetadata.h"
#import "IMPModelDownloader.h"

@interface IMPModel ()
// Private vars

@property (strong, atomic) IMPChooser *chooser;
@property (strong, atomic) IMPTracker *tracker;

@end

@implementation IMPModel
@synthesize model = _model;
@synthesize configuration = _configuration;

+ (void)modelWithContentsOfURL:(NSURL *)url
            configuration:(IMPModelConfiguration *)configuration
        completionHandler:(void (^)(IMPModel * _Nullable model, NSError * _Nullable error))handler
{
    [[[IMPModelDownloader alloc] initWithURL:url maxAge:configuration.cacheMaxAge] downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable downloadError) {
        if (downloadError) {
            handler(nil, downloadError);
            return;
        }
       
        NSError *modelError;
        MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&modelError];
        if (modelError) {
            handler(nil, modelError);
            return;
        }
        handler([[IMPModel alloc] initWithModel:model configuration:configuration], nil);
    }];
}

- (instancetype) initWithModel:(MLModel *) model configuration:(IMPModelConfiguration *)configuration;
{
    self = [super init];
    if (!self) return nil;

    self.model = model; // call setter to set up metadata and chooser
    if (configuration) {
        self.configuration = configuration; // call setter to set up tracker
    }
    
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
        
        NSString *jsonMetadata = model.modelDescription.metadata[@"json"];

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

        _chooser = [[IMPChooser alloc] initWithModel:model metadata:metadata];
        if (!_chooser) {
            IMPErrLog("Failed to initialize Chooser: %@", error);
        }
    }
}

- (IMPModelConfiguration *) configuration
{
    @synchronized (self) {
        return _configuration;
    }
}

- (void) setConfiguration:(IMPModelConfiguration *)configuration
{
    @synchronized (self) {
        _configuration = configuration;
        if (configuration && configuration.trackUrl) {
            _tracker = [[IMPTracker alloc] initWithConfiguration:configuration];
        }
    }
}

- (id) choose:(NSArray *) variants
{
    return [self choose:variants context:nil];
}

- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for choose variants. returning nil.");
            return nil;
        }
        
    //    if (self.shouldTrackVariants) {
    //        [self track:@{
    //            kTypeKey: kVariantsType,
    //            kMethodKey: kChooseMethod,
    //            kVariantsKey: variants
    //        }];
    //    }

        id chosen;

        if (self.chooser) {
            chosen = [self.chooser choose:variants context:context];
        } else {
            IMPErrLog("Model not loaded.");
        }
        
        if (!chosen) {
            IMPErrLog("Choosing first variant.");
            return [variants objectAtIndex:0];
        }

        return chosen;
    }
}


- (NSArray *) sort:(NSArray *) variants
{
    return [self sort:variants context:nil];
}

- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. returning empty array");
            return @[];
        }
        
    //    if (self.shouldTrackVariants) {
    //        [self track:@{
    //            kTypeKey: kVariantsType,
    //            kMethodKey: kSortMethod,
    //            kVariantsKey: variants
    //        }];
    //    }
        
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
    @synchronized (self) {
        if (self.tracker) {
            [self.tracker trackDecision:variant
                                context:context
                              rewardKey:rewardKey
                              modelName:self.modelName
                             completion:nil];
        } else {
            IMPErrLog("Attempted to call trackDecision with nil tracker");
        }
    }
}

- (void) addReward:(NSNumber *) reward
{
    [self addReward:reward forKey:self.modelName];
}

- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey
{
    @synchronized (self) {
        if (self.tracker) {
            [self.tracker addReward:reward forKey:rewardKey completion:nil];
        } else {
            IMPErrLog("Attempted to call addReward with nil tracker");
        }
    }
}

- (void) addRewards:(NSDictionary *)rewards
{
    @synchronized (self) {
        if (self.tracker) {
            [self.tracker addRewards:rewards completion:nil];
        } else {
            IMPErrLog("Attempted to call addRewards with nil tracker");
        }
    }
}

@end
