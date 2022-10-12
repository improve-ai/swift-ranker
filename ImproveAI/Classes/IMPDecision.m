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

//Package priveate properties
@interface IMPDecision ()

@property (nonatomic, strong) IMPDecisionModel *model;

@property (nonatomic, copy, readwrite) NSArray *variants;

@property(nonatomic, strong) NSArray<NSNumber *> *scores;

@end

@implementation IMPDecision

- (instancetype)initWithModel:(IMPDecisionModel *)model rankedVariants:(NSArray *)rankedVariants givens:(NSDictionary *)givens
{
    if(self = [super init]) {
        _model = model;
        _ranked = rankedVariants;
        _givens = givens;
    }
    return self;
}

- (id)best {
    return _ranked[0];
}

- (id)peek
{
    return _ranked[0];
}

- (id)get
{
    @synchronized (self) {
        if(_id == nil) {
            IMPDecisionTracker *tracker = _model.tracker;
            if (tracker == nil) {
                IMPLog("trackURL not set for the underlying DecisionModel. The decision won't be tracked.");
            } else {
                _id = [tracker track:_ranked given:_givens modelName:_model.modelName];
            }
        }
    }
    return _ranked[0];
}

// SecRandomCopyBytes() may fail leading to a nil ksuid. This case is ignored at the moment.
// We assume track() always returns a nonnull id.
- (NSString *)track
{
    @synchronized (self) {
        if(_id != nil) {
            @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"the decision is already tracked!" userInfo:nil];
        }
        
        IMPDecisionTracker *tracker = _model.tracker;
        if (tracker == nil) {
            @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"trackURL of the underlying DecisionModel is nil!" userInfo:nil];
        }
        
        _id = [tracker track:_ranked given:_givens modelName:_model.modelName];
        
        return _id;
    }
}

// For which(), whichFrom(), and optimize().
- (void)trackWith:(IMPDecisionTracker *)tracker
{
    if(tracker != nil) {
        [tracker track:_ranked given:_givens modelName:_model.modelName];
    }
}

- (void)addReward:(double)reward
{
    if(_id == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"addReward() can't be called before track()." userInfo:nil];
    }
    [self.model addReward:reward decision:_id];
}

@end
