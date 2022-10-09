//
//  IMPGivensProvider.h
//  Tests
//
//  Created by PanHongxi on 10/27/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

@protocol IMPGivensProvider <NSObject>

- (NSDictionary<NSString *, id> *)givensForModel:(IMPDecisionModel *)decisionModel givens:(nullable NSDictionary *)givens;

@end

NS_ASSUME_NONNULL_END
