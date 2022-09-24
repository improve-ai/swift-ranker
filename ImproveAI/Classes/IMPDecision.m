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

- (id)get
{
    return _rankedVariants[0];
}

- (NSArray *)ranked
{
    return _rankedVariants;
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
        
        _id = [tracker track:_rankedVariants given:_givens modelName:_model.modelName];
        
        return _id;
    }
}

// For which(), whichFrom(), rank() and optimize().
- (void)trackWith:(IMPDecisionTracker *)tracker
{
    if(tracker != nil) {
        [tracker track:_rankedVariants given:_givens modelName:_model.modelName];
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
