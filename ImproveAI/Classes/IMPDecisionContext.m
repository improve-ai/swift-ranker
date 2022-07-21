//
//  IMPDecisionContext.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 1/14/22.
//  Copyright © 2022 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionContext.h"
#import "IMPDecisionModel.h"
#import "IMPLogging.h"

@interface IMPDecision ()

@property(nonatomic, strong) NSArray *scores;

@property (nonatomic, copy, readwrite) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property(nonatomic, strong) id best;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

@end

@interface IMPDecisionModel ()

- (NSArray<NSNumber *> *)scoreInternal:(NSArray *)variants allGivens:(nullable NSDictionary <NSString *, id>*)givens;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)generateDescendingGaussians:(NSUInteger) count;

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

- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    
    NSArray *scores = [_model scoreInternal:variants allGivens:allGivens];
    
    id best = [IMPDecisionModel topScoringVariant:variants withScores:scores];
    
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:_model];
    decision.variants = variants;
    decision.best = best;
    decision.givens = allGivens;
    decision.scores = scores;
    
    return decision;
}

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores
{
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    id best = [IMPDecisionModel topScoringVariant:variants withScores:scores];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:self.model];
    decision.variants = variants;
    decision.best = best;
    decision.givens = allGivens;
    decision.scores = scores;
    return decision;
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

- (id)first:(NSInteger)n args:(va_list)args
{
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < n; ++i) {
        [variants addObject:va_arg(args, id)];
    }
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
        return [[self chooseFirst:variants[0]] get];
    }
    
    return [[self chooseFirst:variants] get];
}

- (IMPDecision *)chooseRandom:(NSArray *)variants
{
    IMPDecision *decision = [self.model chooseRandom:variants];
    decision.givens = [_model.givensProvider givensForModel:_model givens:_givens];;
    return decision;
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

- (id)random:(NSInteger)n args:(va_list)args
{
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < n; ++i) {
        [variants addObject:va_arg(args, id)];
    }
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
        return [[self chooseRandom:variants[0]] get];
    }
    
    return [[self chooseRandom:variants] get];
}

- (IMPDecision *)chooseMultivariate:(NSDictionary<NSString *, id> *)variants
{
    NSMutableArray *allKeys = [[NSMutableArray alloc] initWithCapacity:[variants count]];
    
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[variants count]];
    [variants enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if(![obj isKindOfClass:[NSArray class]]) {
            [categories addObject:@[obj]];
        } else {
            [categories addObject:obj];
        }
        // I'm not sure whether the order of keys in [variants allKeys] and the enumeration
        // here is the same, so I'm adding the keys to a new array here anyway for safety.
        [allKeys addObject:key];
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

- (id)optimize:(NSDictionary<NSString *, id> *)variants
{
    return [[self chooseMultivariate:variants] get];
}

- (NSArray<NSNumber *> *)score:(NSArray *)variants
{
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    return [_model scoreInternal:variants allGivens:allGivens];
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
    return [self whichInternal:variants];
}

- (id)whichInternal:(NSArray *)variants
{
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"which() expects at least one argument." userInfo:nil];
    }
    
    if([variants count] == 1) {
        id firstVariant = variants[0];
        if([firstVariant isKindOfClass:[NSArray class]] && [firstVariant count] > 0) {
            return [[self chooseFrom:firstVariant] get];
        }
        NSString *reason = @"If only one argument, it must be a nonempty NSArray.";
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    return [[self chooseFrom:variants] get];
}

@end
