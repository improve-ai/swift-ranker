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

@property (nonatomic, copy) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property(nonatomic, strong) id best;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

@end

@interface IMPDecisionModel ()

- (NSArray<NSNumber *> *)scoreInternal:(NSArray *)variants allGivens:(nullable NSDictionary <NSString *, id>*)givens;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

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

- (IMPDecision *)chooseMultiVariate:(NSDictionary<NSString *, id> *)variants
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

- (id)which:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(which(_:_:))
{
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < n; ++i) {
        [variants addObject:va_arg(args, id)];
    }
    return [self whichInternal:variants];
}

- (id)whichInternal:(NSArray *)variants
{
    if([variants count] == 1) {
        id firstVariant = variants[0];
        if([firstVariant isKindOfClass:[NSArray class]]) {
            if([firstVariant count] <= 0) {
                NSString *reason = @"If only one argument, it must be a non-empty NSArray or a non-empty NSDictionary";
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            }
            return [[self chooseFrom:firstVariant] get];
        } else if([firstVariant isKindOfClass:[NSDictionary class]]) {
            if([firstVariant count] <= 0) {
                NSString *reason = @"If only one argument, it must be a non-empty NSArray or a non-empty NSDictionary";
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
            }
            return [[self chooseMultiVariate:firstVariant] get];
        } else {
            NSString *reason = @"If only one argument, it must be a non-empty NSArray or a non-empty NSDictionary";
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
    }
    return [[self chooseFrom:variants] get];
}

@end
