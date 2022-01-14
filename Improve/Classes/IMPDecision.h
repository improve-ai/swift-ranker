//
//  IMPDecision.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "IMPDecisionModel.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(Decision)
@interface IMPDecision : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

/**
 * Get the chosen variant and track the decision. The decision would be tracked only once.
 * @return Returns the chosen variant memoized.
 * @throws IMPIllegalStateException Thrown if called before chooseFrom()
 */
- (nullable id)get;

/**
 * Same as get() except that peek won't track the decision.
 * @return Returns the chosen variant memoized.
 * @throws IMPIllegalStateException Thrown if called before chooseFrom()
 */
- (nullable id)peek;

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
