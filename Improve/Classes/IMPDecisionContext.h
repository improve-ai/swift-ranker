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

- (instancetype)initWithModel:(IMPDecisionModel *)model andGivens:(nullable NSDictionary *)givens;

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @return An IMPDecision object.
 * @throws NSInvalidArgumentException Thrown if the variants to choose from is empty or nil
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

/**
 * This method is an alternative of chooseFrom(). An example here might be more expressive:
 * chooseMutilVariate({"style":["bold", "italic"], "size":[3, 5]})
 *       is equivalent to
 * chooseFrom([
 *      {"style":"bold", "size":3},
 *      {"style":"italic", "size":3},
 *      {"style":"bold", "size":5},
 *      {"style":"italic", "size":5},
 * ])
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity like chooseFrom().
 * The value of the dictionary is expected to be an NSArray. If not, it would be treated as an one-element NSArray anyway.
 * So chooseMutilVariate({"style":["bold", "italic", "size":3}) is equivalent to chooseMutilVariate({"style":["bold", "italic", "size":[3]})
 * @return An IMPDecision object.
 * @throws NSInvalidArgumentException Thrown if the variants to choose from is empty or nil
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
 * This method is a short hand of chooseFrom(variants).get().
 * @param firstVariant If there's only one variant, then the firstVariant must be an NSArray or an NSDictionary.
 * When the only argument is an NSArray, it's equivalent to calling chooseFrom(firstVariant).get();
 * When the only argument is an NSDictionary, it's equivalent to calling chooseMultiVariate(firstVariant).get();
 * When there are two or more arguments, all the arguments would form an NSArray and be passed to chooseFrom()
 * Primitive type arguments are not allowed.
 * @return Returns the chosen variant.
 * @throws NSInvalidArgumentException Thrown if there's only one argument and it's not an NSArray or NSDictionary.
 */
- (id)which:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

- (id)which:(id)firstVariant args:(va_list)args NS_SWIFT_NAME(which(_:_:));

@end

NS_ASSUME_NONNULL_END
