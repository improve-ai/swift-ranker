//
//  IMPDecision.m
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecision.h"
#import "IMPLogging.h"

// Package private methods
@interface IMPDecisionModel ()

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

- (NSDictionary *)collectAllGivens;

@end

// "Package private" methods
@interface IMPDecisionTracker ()

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount;

- (void)track:(id)variant variants:(NSArray *)variants given:(NSDictionary *)givens modelName:(NSString *)modelName variantsRankedAndTrackRunnersUp:(BOOL) variantsRankedAndTrackRunnersUp;
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

- (instancetype)given:(NSDictionary <NSString *, id>*)givens
{
    if (_chosen) {
        IMPErrLog("variant already chosen, ignoring givens");
    } else {
        _givens = givens;
    }
    
    return self;
}

- (id)get
{
    @synchronized (self) {
        if (_chosen) {
            // if get() was previously called
            return _best;
        }
        
        NSMutableDictionary *allGivens = [NSMutableDictionary dictionaryWithDictionary:_givens];
        [allGivens addEntriesFromDictionary:[_model collectAllGivens]];
        
        for(NSString *key in [allGivens allKeys]) {
          IMPLog("givens: %@=%@", key, [allGivens objectForKey:key]);
        }
        
        NSArray *scores = [_model score:_variants given:allGivens];

        if (_variants && _variants.count) {
            if (_model.tracker) {
                if ([_model.tracker shouldTrackRunnersUp:_variants.count]) {
                    // the more variants there are, the less frequently this is called
                    NSArray *rankedVariants = [IMPDecisionModel rank:_variants withScores:scores];
                    _best = rankedVariants.firstObject;
                    [_model.tracker track:_best variants:rankedVariants given:allGivens modelName:_model.modelName variantsRankedAndTrackRunnersUp:TRUE];
                } else {
                    // faster and more common path, avoids array sort
                    _best = [IMPDecisionModel topScoringVariant:_variants withScores:scores];
                    [_model.tracker track:_best variants:_variants given:allGivens modelName:_model.modelName variantsRankedAndTrackRunnersUp:FALSE];
                }
            } else {
                _best = [IMPDecisionModel topScoringVariant:_variants withScores:scores];
            }
        } else {
            // Unit test that "variant": null JSON is tracked on null or empty variants.
            // "count" field should be 1
            _best = nil;
            [_model.tracker track:_best variants:nil given:allGivens modelName:_model.modelName variantsRankedAndTrackRunnersUp:NO];
        }

        _chosen = TRUE;
    }

    return _best;
}

@end
