//
//  IMPDecisionContext.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 1/14/22.
//  Copyright © 2022 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPDecision.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionContext)
@interface IMPDecisionContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModel:(IMPDecisionModel *)model andGivens:(nullable NSDictionary *)givens;

/**
 * @see IMPDecisionModel.chooseFrom()
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores NS_SWIFT_NAME(chooseFrom(_:_:));

/**
 * @see IMPDecisionModel.chooseFirst()
 */
- (IMPDecision *)chooseFirst:(NSArray *)variants NS_SWIFT_NAME(chooseFirst(_:));

/**
 * @see IMPDecisionModel.first()
 */
- (id)first:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

- (id)first:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(first(_:_:));

/**
 * @see IMPDecisionModel.chooseRandom()
 */
- (IMPDecision *)chooseRandom:(NSArray *)variants NS_SWIFT_NAME(chooseRandom(_:));

/**
 * @see IMPDecisionModel.random()
 */
- (id)random:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

- (id)random:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(random(_:_:));

/**
 * @see IMPDecisionModel#chooseMultiVariate()
 */
- (IMPDecision *)chooseMultiVariate:(NSDictionary<NSString *, id> *)variants NS_SWIFT_NAME(chooseMultiVariate(_:));

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @throws NSInvalidArgumentException Thrown if variants is nil or empty.
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants NS_SWIFT_NAME(score(_:));

/**
 * @see IMPDecisionModel.which()
 */
- (id)which:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

- (id)which:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(which(_:_:));

@end

NS_ASSUME_NONNULL_END
