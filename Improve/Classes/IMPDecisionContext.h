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

- (IMPDecision *)chooseFrom:(NSArray *)variants;

@end

NS_ASSUME_NONNULL_END
