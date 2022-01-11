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

@property(nonatomic, strong) NSArray *scores;

@property(nonatomic, strong) NSDictionary *allGivens;

/**
 * A decision should be tracked only once when calling get(). A boolean here may
 * be more appropriate in the first glance. But I find it hard to unit test
 * that it's tracked only once with a boolean value in multi-thread mode. So I'm
 * using an int here with 0 as 'untracked', and anything else as 'tracked'.
 */
@property(nonatomic, readonly) int tracked;

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
    @synchronized (self) {
        if (_chosen) {
            IMPErrLog("variant already chosen, ignoring variants");
            return self;
        }
        
        if([variants count] <= 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants to choose from can't be nil or empty" userInfo:nil];
        }
        
        _variants = variants;
        
        _allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
        
        _scores = [_model score:_variants given:_allGivens];
        
        _best = [IMPDecisionModel topScoringVariant:_variants withScores:_scores];

        _chosen = TRUE;
    }
    return self;
}

- (void) setGivens:(NSDictionary <NSString *, id>*)givens
{
    @synchronized (self) {
        if (_chosen) {
            IMPErrLog("variant already chosen, ignoring givens");
        } else {
            _givens = givens;
        }
    }
}

- (id)peek
{
    if(!_chosen) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"peek() must be called after chooseFrom()" userInfo:nil];
    }
    return _best;
}

- (id)get
{
    @synchronized (self) {
        if (!_chosen) {
            @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"get() must be called after chooseFrom()" userInfo:nil];
        }
        // No matter how many times get() is called, we only call track for once.
        if(_tracked == 0) {
            IMPDecisionTracker *tracker = _model.tracker;
            if (tracker) {
                if ([tracker shouldTrackRunnersUp:_variants.count]) {
                    // the more variants there are, the less frequently this is called
                    NSArray *rankedVariants = [IMPDecisionModel rank:_variants withScores:_scores];
                    _id = [tracker track:_best variants:rankedVariants given:_allGivens modelName:_model.modelName variantsRankedAndTrackRunnersUp:TRUE];
                } else {
                    // faster and more common path, avoids array sort
                    _id = [tracker track:_best variants:_variants given:_allGivens modelName:_model.modelName variantsRankedAndTrackRunnersUp:FALSE];
                }
                _tracked++;
            } else {
                IMPErrLog("trackURL of the underlying DecisionModel is nil, decision will not be tracked");
            }
        }
    }
    return _best;
}

- (void)addReward:(double)reward
{
    if(_id == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"_id can't be nil. Make sure that addReward() is called after get(); and trackURL is set in the DecisionModel." userInfo:nil];
    }
    [self.model addReward:reward decision:_id];
}

@end
