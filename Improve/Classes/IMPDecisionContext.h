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
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @throws NSInvalidArgumentException Thrown if variants is nil or empty.
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants NS_SWIFT_NAME(score(_:));

@end

NS_ASSUME_NONNULL_END
