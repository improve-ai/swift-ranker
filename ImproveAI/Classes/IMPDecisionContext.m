//
//  IMPDecisionContext.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 1/14/22.
//  Copyright © 2022 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionContext.h"
#import "IMPDecisionModel.h"
#import "Tracker/IMPDecisionTracker.h"
#import "IMPLogging.h"

@interface IMPDecision ()

@property(nonatomic, strong) NSArray *scores;

@property (nonatomic, copy, readwrite) NSArray *variants;

- (instancetype)initWithModel:(IMPDecisionModel *)model rankedVariants:(NSArray *)rankedVariants givens:(NSDictionary *)givens;

- (void)trackWith:(IMPDecisionTracker *)tracker;

@end

@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

- (NSArray<NSNumber *> *)scoreInternal:(NSArray *)variants allGivens:(nullable NSDictionary <NSString *, id>*)givens;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)generateDescendingGaussians:(NSUInteger) count;

+ (NSArray *)generateRandomScores:(NSUInteger)count;

+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

- (BOOL)isLoaded;

@end

@interface IMPDecisionContext ()

@property (nonatomic, strong) IMPDecisionModel *model;

@property (nonatomic, strong) NSDictionary *givens;

@end

@implementation IMPDecisionContext

- (instancetype)initWithModel:(IMPDecisionModel *)model andGivens:(NSDictionary *)givens
{
    if(self = [super init]) {
        _model = model;
        _givens = givens;
    }
    return self;
}

- (NSArray<NSNumber *> *)score:(NSArray *)variants
{
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    return [_model scoreInternal:variants allGivens:allGivens];
}

- (IMPDecision *)decide:(NSArray *)variants
{
    return [self decide:variants ordered:false];
}

- (IMPDecision *)decide:(NSArray *)variants ordered:(BOOL)ordered
{
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants can't be nil or empty." userInfo:nil];
    }
    
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    
    NSArray *rankedVariants;
    if (ordered) {
        rankedVariants = [NSArray arrayWithArray:variants];
    } else {
        if([_model isLoaded]) {
            NSArray<NSNumber *> *scores = [_model scoreInternal:variants allGivens:allGivens];
            rankedVariants = [IMPDecisionModel rank:variants withScores:scores];
        } else {
            rankedVariants = [NSArray arrayWithArray:variants];
        }
    }
    
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:_model rankedVariants:rankedVariants givens:allGivens];
    decision.variants = variants;
    
    return decision;
}

- (IMPDecision *)decide:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores
{
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    id rankedVariants = [IMPDecisionModel rank:variants withScores:scores];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:_model rankedVariants:rankedVariants givens:allGivens];
    decision.variants = variants;
    return decision;
}

- (id)which:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"which() expects at least one argument." userInfo:nil];
    }
    
    return [self whichFrom:variants];
}

- (id)whichFrom:(NSArray *)variants
{
    IMPDecision *decision = [self decide:variants];
    [decision trackWith:_model.tracker];
    return [decision get];
}

- (NSArray *)rank:(NSArray *)variants
{
    IMPDecision *decision = [self decide:variants];
    [decision trackWith:_model.tracker];
    return [decision ranked];
}

- (id)optimize:(NSDictionary<NSString *, id> *)variantMap
{
    return [self whichFrom:[self.model fullFactorialVariants:variantMap]];
}

#pragma mark - Deprecated, remove in 8.0.

- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    return [self decide:variants];
}

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores
{
    return [self decide:variants scores:scores];
}

- (IMPDecision *)chooseFirst:(NSArray *)variants NS_SWIFT_NAME(chooseFirst(_:))
{
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants can't be nil or empty." userInfo:nil];
    }
    NSArray *scores = [IMPDecisionModel generateDescendingGaussians:[variants count]];
    return [self chooseFrom:variants scores:scores];
}

- (id)first:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    return [self firstInternal:variants];
}

- (id)firstInternal:(NSArray *)variants
{
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"first() expects at least one argument." userInfo:nil];
    }
    
    if([variants count] == 1) {
        if(![variants[0] isKindOfClass:[NSArray class]]) {
            NSString *reason = @"If only one argument, it must be an NSArray.";
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
        IMPDecision *decision = [self chooseFirst:variants[0]];
        [decision trackWith:_model.tracker];
        return [decision get];
    }
    
    IMPDecision *decision = [self chooseFirst:variants];
    [decision trackWith:_model.tracker];
    return [decision get];
}

- (IMPDecision *)chooseRandom:(NSArray *)variants
{
    if([variants count] <= 0) {
        NSString *reason = @"variants can't be nil or empty.";
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    return [self decide:variants scores:[IMPDecisionModel generateRandomScores:[variants count]]];
}

- (id)random:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    return [self randomInternal:variants];
}

- (id)randomInternal:(NSArray *)variants
{
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"random() expects at least one argument." userInfo:nil];
    }
    if([variants count] == 1) {
        if(![variants[0] isKindOfClass:[NSArray class]]) {
            NSString *reason = @"If only one argument, it must be an NSArray.";
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
        IMPDecision *decision = [self chooseRandom:variants[0]];
        [decision trackWith:_model.tracker];
        return [decision get];
    }
    
    IMPDecision *decision = [self chooseRandom:variants];
    [decision trackWith:_model.tracker];
    return [decision get];
}

- (IMPDecision *)chooseMultivariate:(NSDictionary<NSString *, id> *)variants
{
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithCapacity:[variants count]];
    
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[variants count]];
    [variants enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if(![obj isKindOfClass:[NSArray class]]) {
            [categories addObject:@[obj]];
            [allKeys addObject:key];
        } else {
            if([obj count] > 0) {
                [categories addObject:obj];
                [allKeys addObject:key];
            }
        }
    }];
    
    NSMutableArray<NSDictionary *> *combinations = [[NSMutableArray alloc] init];
    for(int i = 0; i < [categories count]; ++i) {
        NSArray *category = categories[i];
        NSMutableArray<NSDictionary *> *newCombinations = [[NSMutableArray alloc] init];
        for(int m = 0; m < [category count]; ++m) {
            if([combinations count] == 0) {
                [newCombinations addObject:@{allKeys[i]:category[m]}];
            } else {
                for(int n = 0; n < [combinations count]; ++n) {
                    NSMutableDictionary *newVariant = [combinations[n] mutableCopy];
                    [newVariant setObject:category[m] forKey:allKeys[i]];
                    [newCombinations addObject:newVariant];
                }
            }
        }
        combinations = newCombinations;
    }
    IMPLog("Choosing from %ld combinations", [combinations count]);
    
    return [self chooseFrom:combinations];
}

@end
