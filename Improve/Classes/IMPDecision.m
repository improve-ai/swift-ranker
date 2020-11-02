//
//  IMPDecision.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/19/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecision.h"
#import "IMPScoredVariant.h"

// "Package private" methods
@interface IMPDecisionModel ()
+ (NSArray *)rankScoredVariants:(NSArray *)scored;
/// Performs reservoir sampling to break ties when variants have the same score.
+ (nullable id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores;
@end

@implementation IMPDecision

@synthesize scores = _scores;
@synthesize scored = _scored;
@synthesize ranked = _ranked;
@synthesize best = _best;

+ (NSDictionary *)simpleContext {
    return @{};
}

- (instancetype)initWithVariants:(NSArray *)variants
                           model:(IMPDecisionModel *)model
                         tracker:(IMPDecisionTracker *)tracker
{
    return [self initWithVariants:variants
                            model:model
                          tracker:tracker];
}

- (instancetype)initWithVariants:(NSArray *)variants
                           model:(IMPDecisionModel *)model
                         tracker:(IMPDecisionTracker *)tracker
                         context:(nullable NSDictionary *)context
{
    self = [super init];
    if (!self) return nil;

    /*
     Shallow-copy all collections to insure immutability. NSArray and
     NSDictionary support copy-on-write, so this operation wouldn't be expensive.
     */
    _variants = [variants copy];
    _model = model;
    _modelName = model.name;
    _tracker = tracker;
    _context = (context != nil) ? [context copy] : [self.class simpleContext];
    _maxRunnersUp = 50;

    return self;
}

- (instancetype)initWithRankedVariants:(NSArray *)rankedVariants
                             modelName:(NSString *)modelName
                               tracker:(IMPDecisionTracker *)tracker
{
    return [self initWithRankedVariants:rankedVariants
                              modelName:modelName
                                tracker:tracker
                                context:nil];
}

- (instancetype)initWithRankedVariants:(NSArray *)rankedVariants
                             modelName:(NSString *)modelName
                               tracker:(IMPDecisionTracker *)tracker
                               context:(nullable NSDictionary *)context
{
    self = [super init];
    if (!self) return nil;

    /*
     Shallow-copy all collections to insure immutability. NSArray and
     NSDictionary support copy-on-write, so this operation wouldn't be expensive.
     */
    _variants = [rankedVariants copy];
    _modelName = [modelName copy];
    _tracker = tracker;
    _context = (context != nil) ? [context copy] : [self.class simpleContext];

    NSMutableArray *randomScores = [NSMutableArray arrayWithCapacity:rankedVariants.count];
    for (NSUInteger i = 0; i < rankedVariants.count; i++)
    {
        [randomScores addObject:@(drand48())];
    }
    [randomScores sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]];
    _scores = [randomScores copy];
    _ranked = _variants;

    return self;
}

- (nullable id)best
{
    if (_best) return _best;
    if (self.variants.count == 0) return nil;

    if (_ranked) {
        _best = self.ranked.firstObject;
        return _best;
    }

    _best = [IMPDecisionModel bestSampleFrom:self.variants
                                   forScores:self.scores];
    return _best;
}

- (NSArray *)ranked
{
    if (_ranked) return _ranked;

    _ranked = [IMPDecisionModel rankScoredVariants:self.scored];
    return _ranked;
}

- (NSArray *)scored
{
    if (_scored) return _scored;

    NSUInteger count = self.variants.count;
    NSArray *scores = self.scores;
    NSMutableArray *scoredVariants = [NSMutableArray arrayWithCapacity:count];

    for (NSUInteger i = 0; i < count; i++)
    {
        [scoredVariants addObject:[IMPScoredVariant withScore:[scores[i] doubleValue] variant:self.variants[i]]];
    }

    // Copy
    _scored = [scoredVariants copy];
    return _scored;
}

- (NSArray<NSNumber *> *)scores
{
    if (_scores) return _scores;

    _scores = [self.model score:self.variants];
    return _scores;
}

- (NSArray *)topRunnersUp
{
    NSRange range = NSMakeRange(0, MIN(self.maxRunnersUp, self.ranked.count));
    return [self.ranked subarrayWithRange:range];
}

- (BOOL)shouldTrackRunnersUp
{
    return drand48() < 1.0 / MIN(self.variants.count - 1, self.maxRunnersUp);
}

@end
