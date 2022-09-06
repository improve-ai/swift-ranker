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
 * Equivalent to get(trackOnce=True)
 */
- (id)get;

/**
 * Get the chosen variant and track the decision.
 * @param trackOnce If true, the decision would be tracked only once no matter how many times
 * get()/ranked() is called; otherwise, the decision would not be tracked.
 * @return Returns the chosen variant.
 */
- (id)get:(BOOL)trackOnce;

/**
 * Equivalent to ranked(trackOnce=True)
 */
- (NSArray *)ranked;

/**
 * Get the ranked variants and track the decision.
 * @param trackOnce If true, the decision would be tracked only once no matter how many times
 * get()/ranked() is called; otherwise, the decision would not be tracked.
 * @return Returns the ranked variants.
 */
- (NSArray *)ranked:(BOOL)trackOnce;

/**
 * Same as get() except that peek won't track the decision.
 * @return Returns the chosen variant memoized.
 * @throws IMPIllegalStateException Thrown if called before chooseFrom()
 */
- (id)peek DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * Add rewards that only apply to this specific decision. Must be called after get().
 * @throws NSInvalidArgumentException Thrown if reward is NaN or +-Infinity
 * @throws IMPIllegalStateException Thrown if the trackURL of the underlying DecisionModel is nil, or _id is nil.
 * The _id could be nil when addReward() is called prior to get(), or less likely the system clock is so
 * biased(beyond 2014~2150) that we can't generate a valid id(ksuid) when get() is called.
 */
- (void)addReward:(double)reward;

@end

NS_ASSUME_NONNULL_END
