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

- (nullable NSString *)track:(NSArray *)rankedVariants given:(NSDictionary *)givens modelName:(NSString *)modelName;

@end

//Package priveate properties
@interface IMPDecision ()

@property (nonatomic, strong, readonly) NSString *id;

@property (nonatomic, strong) IMPDecisionModel *model;

@property (nonatomic, copy, readwrite) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property (nonatomic, strong) NSArray *rankedVariants;

/**
 * A decision should be tracked only once when calling get(). A boolean here may
 * be more appropriate in the first glance. But I find it hard to unit test
 * that it's tracked only once with a boolean value in multi-thread mode. So I'm
 * using an int here with 0 as 'untracked', and anything else as 'tracked'.
 */
@property(nonatomic, readonly) int tracked;

@end

@implementation IMPDecision

- (instancetype)initWithModel:(IMPDecisionModel *)model rankedVariants:(NSArray *)rankedVariants givens:(NSDictionary *)givens
{
    if(self = [super init]) {
        _model = model;
        _rankedVariants = rankedVariants;
        _givens = givens;
    }
    return self;
}

- (id)peek
{
    return _rankedVariants[0];
}

- (id)get
{
    return [self get:YES];
}

- (id)get:(BOOL)trackOnce
{
    if (trackOnce) {
        [self trackOnce];
    }
    return _rankedVariants[0];
}

- (NSArray *)ranked
{
    return [self ranked:YES];
}

- (NSArray *)ranked:(BOOL)trackOnce
{
    if (trackOnce) {
        [self trackOnce];
    }
    return _rankedVariants;
}

- (void)addReward:(double)reward
{
    if(_id == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"_id can't be nil. Make sure that addReward() is called after get(); and trackURL is set in the DecisionModel." userInfo:nil];
    }
    [self.model addReward:reward decision:_id];
}

- (void)trackOnce
{
    @synchronized (self) {
        // No matter how many times get() is called, we only call track for once.
        if(_tracked == 0) {
            IMPDecisionTracker *tracker = _model.tracker;
            if (tracker) {
                _id = [tracker track:_rankedVariants given:_givens modelName:_model.modelName];
                _tracked++;
            } else {
                IMPErrLog("trackURL of the underlying DecisionModel is nil, decision will not be tracked");
            }
        }
    }
}

@end
