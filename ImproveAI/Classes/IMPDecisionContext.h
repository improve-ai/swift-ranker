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

@interface IMPDecisionContext : NSObject

- (instancetype)init NS_UNAVAILABLE;

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @throws NSInvalidArgumentException Thrown if variants is nil or empty.
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants NS_SWIFT_NAME(score(_:));

/**
 * @see IMPDecisionModel.decide()
 */
- (IMPDecision *)decide:(NSArray *)variants NS_SWIFT_NAME(decide(_:));

/**
 * @see IMPDecisionModel.decide()
 */
- (IMPDecision *)decide:(NSArray *)variants ordered:(BOOL)ordered NS_SWIFT_NAME(decide(_:_:));

/**
 * @see IMPDecisionModel.decide()
 */
- (IMPDecision *)decide:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores NS_SWIFT_NAME(decide(_:_:));

/**
 * @see IMPDecisionModel.which()
 */
- (id)which:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

/**
 * @see IMPDecisionModel.whichFrom()
 */
- (id)whichFrom:(NSArray *)variants NS_SWIFT_NAME(whichFrom(_:));

/**
 * @see IMPDecisionModel.rank()
 */
- (NSArray *)rank:(NSArray *)variants NS_SWIFT_NAME(rank(_:));

/**
 * @see IMPDecisionModel#optimize()
 */
- (NSDictionary<NSString*, id> *)optimize:(NSDictionary<NSString *, id> *)variantMap NS_SWIFT_NAME(optimize(_:));

#pragma mark - Deprecated, remove in 8.0

/**
 * @see IMPDecisionModel.chooseFrom()
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores NS_SWIFT_NAME(chooseFrom(_:_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * @see IMPDecisionModel.chooseFirst()
 */
- (IMPDecision *)chooseFirst:(NSArray *)variants NS_SWIFT_NAME(chooseFirst(_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * @see IMPDecisionModel.first()
 */
- (id)first:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

- (id)first:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(first(_:_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * @see IMPDecisionModel.chooseRandom()
 */
- (IMPDecision *)chooseRandom:(NSArray *)variants NS_SWIFT_NAME(chooseRandom(_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * @see IMPDecisionModel.random()
 */
- (id)random:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

- (id)random:(NSInteger)n args:(va_list)args NS_SWIFT_NAME(random(_:_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

/**
 * @see IMPDecisionModel#chooseMultivariate()
 */
- (IMPDecision *)chooseMultivariate:(NSDictionary<NSString *, id> *)variants NS_SWIFT_NAME(chooseMultivariate(_:)) DEPRECATED_MSG_ATTRIBUTE("Remove in 8.0");

@end

NS_ASSUME_NONNULL_END
