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

@property (nonatomic, readonly) IMPDecisionModel *model;

@property (nonatomic, readonly, strong) NSArray *variants;

@property (nonatomic, strong, nullable) NSDictionary *givens;

// id of the tracked decision.
// It's nil until the get() method is called and a decision is tracked.
@property (nonatomic, strong, readonly) NSString *id;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

- (instancetype)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

/**
 * Returns the chosen variant. The chosen variant will be memoized, so same value is returned on subsequent calls.
 * @throws NSInvalidArgumentException Thrown if the variants to choose from is empty or nil
 */
- (nullable id)get;

/**
 * Add rewards that only apply to this specific decision. This method should not be called prior to get().
 * @throws NSInvalidArgumentException Thrown if reward is NaN or +-Infinity
 * @throws IMPIllegalStateException Thrown if the trackURL of the underlying DecisionModel is nil, or _id is nil.
 * The _id could be nil when addReward() is called prior to get(), or less likely the system clock is so
 * biased(beyond 2014~2150) that we can't generate a valid id(ksuid) when get() is called.
 */
- (void)addReward:(double)reward;

@end

NS_ASSUME_NONNULL_END
