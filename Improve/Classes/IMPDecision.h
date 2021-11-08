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
 Return the chosen variant or nil if no variants. The chosen variant will be memoized, so same value is returned on subsequent calls.
 */
- (nullable id)get;

/**
 * Add rewards that only apply to this specific decision. This method should not be called before calling get().
 */
- (void)addReward:(double)reward;

@end

NS_ASSUME_NONNULL_END
