//
//  IMPDecision.m
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecision.h"

// "Package private" methods
@interface IMPDecisionTracker ()

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount;
+ (NSArray *)rankScoredVariants:(NSArray *)scored;
/// Performs reservoir sampling to break ties when variants have the same score.
+ (nullable id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores;

@end

// private vars
@interface IMPDecision ()

@property(nonatomic, readonly, nullable) id best;
@property(nonatomic, readonly) BOOL chosen;

@end

@implementation IMPDecision

- (instancetype)initWithModel:(IMPDecisionModel *)model
{
    self = [super init];
    if (!self) return nil;

    _model = model;

    return self;
}

- (instancetype)chooseFrom:(NSArray *)variants
{
    _variants = variants;
    
    return self;
}

- (instancetype)given:(NSDictionary <NSString *, id>*)givens
{
    _givens = givens;
    
    return self;
}


- (nullable id)get
{
    
    if (_chosen) {
        // if get() was previously called
        return _best;
    }

    NSArray *scores = [_model score:_variants given:_givens];

    NSArray *rankedVariants = nil;

    if (_variants && _variants.count) {
        if (_model.tracker && [_model.tracker shouldTrackRunnersUp:_variants.count]) {
            rankedVariants = [IMPDecisionModel rank:_variants withScores:scores];
            _best = rankedVariants.firstObject;
        } else {
            _best = [IMPDecisionModel topScoringVariant:_variants withScores:scores];
        }
    }

    // make sure to set this before calling track() because tracker will call back to get()
    _chosen = TRUE;
    
    if (_model.tracker) {
        [model.tracker track:self rankedVariants:rankedVariants];
    }

    return _best;
}


@end
