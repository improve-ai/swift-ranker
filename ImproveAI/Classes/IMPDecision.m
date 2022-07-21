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

// Package private methods and properties
@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

@end

// Package private methods
@interface IMPDecisionTracker ()

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount;

- (nullable NSString *)track:(id)variant variants:(NSArray *)variants given:(NSDictionary *)givens modelName:(NSString *)modelName variantsRankedAndTrackRunnersUp:(BOOL) variantsRankedAndTrackRunnersUp;
@end

//Package priveate properties
@interface IMPDecision ()

@property (nonatomic, strong, readonly) NSString *id;

@property(nonatomic, strong) NSArray *scores;

@property (nonatomic, strong) IMPDecisionModel *model;

@property (nonatomic, copy, readwrite) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property (nonatomic, strong) id best;

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

- (id)peek
{
    return _best;
}

- (id)get
{
    @synchronized (self) {
        // No matter how many times get() is called, we only call track for once.
        if(_tracked == 0) {
            IMPDecisionTracker *tracker = _model.tracker;
            if (tracker) {
                if ([tracker shouldTrackRunnersUp:_variants.count]) {
                    // the more variants there are, the less frequently this is called
                    NSArray *rankedVariants = [IMPDecisionModel rank:_variants withScores:_scores];
                    _id = [tracker track:_best variants:rankedVariants given:_givens modelName:_model.modelName variantsRankedAndTrackRunnersUp:TRUE];
                } else {
                    // faster and more common path, avoids array sort
                    _id = [tracker track:_best variants:_variants given:_givens modelName:_model.modelName variantsRankedAndTrackRunnersUp:FALSE];
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
