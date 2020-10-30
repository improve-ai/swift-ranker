//
//  IMPDecision.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/19/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPDecisionModel.h"
#import "IMPDecisionTracker.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecision : NSObject

+ (NSDictionary *)simpleContext;

@property(nonatomic, readonly, nullable) IMPDecisionModel *model;

@property(nonatomic, readonly) NSString *modelName;

@property(nonatomic, readonly) IMPDecisionTracker *tracker;

@property(nonatomic, readonly) NSArray *variants;

@property(nonatomic, readonly) NSDictionary *context;

@property(nonatomic, readonly, nullable) id best;

@property(nonatomic, readonly) NSArray<NSNumber*> *scores;

@property(nonatomic, readonly) NSArray *ranked;

/// Array of IMPScoredVariant objects.
@property(nonatomic, readonly) NSArray *scored;

/// Hyperparameter that affects training speed and model performance. Values from 10-100 are probably reasonable.
@property(nonatomic) NSUInteger maxRunnersUp;

@property(nonatomic, readonly) NSArray *topRunnersUp;

@property(nonatomic, readonly) BOOL shouldTrackRunnersUp;

- (instancetype)initWithVariants:(NSArray *)variants
                           model:(IMPDecisionModel *)model
                         tracker:(IMPDecisionTracker *)tracker;

- (instancetype)initWithVariants:(NSArray *)variants
                           model:(IMPDecisionModel *)model
                         tracker:(IMPDecisionTracker *)tracker
                         context:(nullable NSDictionary *)context;

- (instancetype)initWithRankedVariants:(NSArray *)rankedVariants
                             modelName:(NSString *)modelName
                               tracker:(IMPDecisionTracker *)tracker;

- (instancetype)initWithRankedVariants:(NSArray *)rankedVariants
                             modelName:(NSString *)modelName
                               tracker:(IMPDecisionTracker *)tracker
                               context:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
