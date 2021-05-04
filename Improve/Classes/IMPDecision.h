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

@property (nonatomic, strong) NSArray *variants;

@property (nonatomic, strong, nullable) NSDictionary *givens;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

- (instancetype)chooseFrom:(NSArray *)variants;

- (instancetype)given:(NSDictionary<NSString *, id> *)givens;

- (nullable id)get;

@end

NS_ASSUME_NONNULL_END
