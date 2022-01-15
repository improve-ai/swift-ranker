//
//  IMPDecisionContext.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 1/14/22.
//  Copyright © 2022 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionContext.h"
#import "IMPDecisionModel.h"

@interface IMPDecision ()

@property(nonatomic, strong) NSArray *scores;

@property (nonatomic, copy) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property(nonatomic, strong) id best;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

@end

@interface IMPDecisionModel ()

- (NSArray<NSNumber *> *)score:(NSArray *)variants given:(nullable NSDictionary <NSString *, id>*)givens;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

@end

@interface IMPDecisionContext ()

@property (nonatomic, strong) IMPDecisionModel *model;

@property (nonatomic, strong) NSDictionary *givens;

@end

@implementation IMPDecisionContext

- (instancetype)initWithModel:(IMPDecisionModel *)model andGivens:(NSDictionary *)givens {
    if(self = [super init]) {
        _model = model;
        _givens = givens;
    }
    return self;
}

- (IMPDecision *)chooseFrom:(NSArray *)variants {
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants to choose from can't be nil or empty" userInfo:nil];
    }
    
    NSDictionary *allGivens = [_model.givensProvider givensForModel:_model givens:_givens];
    
    NSArray *scores = [_model score:variants given:allGivens];
    
    id best = [IMPDecisionModel topScoringVariant:variants withScores:scores];
    
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:_model];
    decision.variants = variants;
    decision.best = best;
    decision.givens = allGivens;
    decision.scores = scores;
    
    return decision;
}

@end
