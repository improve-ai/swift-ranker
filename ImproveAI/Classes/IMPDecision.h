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

// The id that uniquely identifies the decision after it's been tracked.
// It's nil until the decision is tracked by calling track().
@property (nonatomic, strong, readonly, nullable) NSString *id;

// The best variant.
@property (nonatomic, strong, readonly) id best;

// The ranked variants.
@property (nonatomic, strong, readonly) NSArray *ranked;

/**
 * Gets the best variant.
 */
- (id)peek DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0.");

/**
 * Gets the best variant, and also track the decision if it's not been tracked yet.
 */
- (id)get DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0.");

/**
 * Tracks the decision.
 * @return Returns the id that uniquely identifies the tracked decision.
 * @throws IMPIllegalStateException Thrown if the trackURL of the underlying IMPDecisionModel is null;
 * Thrown if the decision is already tracked.
 */
- (NSString *)track;

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
