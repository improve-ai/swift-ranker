//
//  IMPDecision.m
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecision.h"
#import "IMPLogging.h"
#import "IMPDecisionTracker.h"
#import "IMPConstants.h"

// Package private methods
@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

- (void)addReward:(double)reward decision:(NSString *)decisionId;

@end

// "Package private" methods
@interface IMPDecisionTracker ()

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount;

- (nullable NSString *)track:(id)variant variants:(NSArray *)variants given:(NSDictionary *)givens modelName:(NSString *)modelName variantsRankedAndTrackRunnersUp:(BOOL) variantsRankedAndTrackRunnersUp;
@end

// private vars
@interface IMPDecision ()

@property(nonatomic, readonly, nullable) id best;

@property(nonatomic, readonly) BOOL chosen;

@end

@implementation IMPDecision

- (instancetype)initWithModel:(IMPDecisionModel *)model
{
    if(self = [super init]) {
        _model = model;
    }
    return self;
}

- (instancetype)chooseFrom:(NSArray *)variants
{
    if (_chosen) {
        IMPErrLog("variant already chosen, ignoring variants");
    } else {
        _variants = variants;
    }
    
    return self;
}

- (void) setGivens:(NSDictionary <NSString *, id>*)givens
{
    if (_chosen) {
        IMPErrLog("variant already chosen, ignoring givens");
    } else {
        _givens = givens;
    }
}

- (id)get
{
    @synchronized (self) {
        if (_chosen) {
            // if get() was previously called
            return _best;
        }
        
        NSDictionary *givens = [_model.givensProvider givensForModel:_model givens:_givens];
        
        NSArray *scores = [_model score:_variants given:givens];

        if (_variants && _variants.count) {
            if (_model.tracker) {
                if ([_model.tracker shouldTrackRunnersUp:_variants.count]) {
                    // the more variants there are, the less frequently this is called
                    NSArray *rankedVariants = [IMPDecisionModel rank:_variants withScores:scores];
                    _best = rankedVariants.firstObject;
                    _id = [_model.tracker track:_best variants:rankedVariants given:givens modelName:_model.modelName variantsRankedAndTrackRunnersUp:TRUE];
                } else {
                    // faster and more common path, avoids array sort
                    _best = [IMPDecisionModel topScoringVariant:_variants withScores:scores];
                    _id = [_model.tracker track:_best variants:_variants given:givens modelName:_model.modelName variantsRankedAndTrackRunnersUp:FALSE];
                }
            } else {
                _best = [IMPDecisionModel topScoringVariant:_variants withScores:scores];
                IMPErrLog("trackURL of the underlying DecisionModel is nil, decision will not be tracked");
            }
        } else {
            // Unit test that "variant": null JSON is tracked on null or empty variants.
            // "count" field should be 1
            _best = nil;
            if(_model.tracker) {
                _id = [_model.tracker track:_best variants:nil given:givens modelName:_model.modelName variantsRankedAndTrackRunnersUp:NO];
            } else {
                IMPErrLog("trackURL of the underlying DecisionModel is nil, decision will not be tracked");
            }
        }

        _chosen = TRUE;
    }

    return _best;
}

- (void)addReward:(double)reward {
    if(_id == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"_id can't be nil when calling addReward()" userInfo:nil];
    }
    [self.model addReward:reward decision:_id];
}

@end
