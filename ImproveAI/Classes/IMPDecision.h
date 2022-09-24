//
//  IMPDecision.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "IMPDecisionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecision : NSObject

@property (nonatomic, copy, readonly) NSArray *variants;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Get the chosen variant.
 */
- (id)get;

/**
 * Get the ranked variants.
 * @return Returns the ranked variants.
 */
- (NSArray *)ranked;

/**
 * Tracks the decision.
 * @return Returns the id that uniquely identifies the tracked decision.
 * @throws IMPIllegalStateException Thrown if the trackURL of the underlying IMPDecisionModel is null;
 * Thrown if the decision is already tracked.
 */
- (nullable NSString *)track;

/**
 * Adds rewards that only apply to this specific decision. Before calling this method, make sure that the decision is
 * already tracked by calling track().
 * @throws NSInvalidArgumentException Thrown if reward is NaN or +-Infinity
 * @throws IMPIllegalStateException Thrown if the trackURL of the underlying DecisionModel is nil; Thrown if the decision
 * is not tracked yet.
 */
- (void)addReward:(double)reward;

@end

NS_ASSUME_NONNULL_END
