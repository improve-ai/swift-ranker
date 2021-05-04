//
//  IMPDecisionModel.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import "IMPDecisionTracker.h"

@class IMPDecision;
@class IMPDecisionModel;

typedef void (^IMPDecisionModelLoadCompletion) (IMPDecisionModel *_Nullable compiledModel, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionModel)
@interface IMPDecisionModel : NSObject

@property(atomic, strong) MLModel *model;

@property(nonatomic, strong) NSString *modelName;

@property(nonatomic, strong) IMPDecisionTracker *tracker;

+ (instancetype)load:(NSURL *)url;
+ (void)loadAsync:(NSURL *)url completion:(IMPDecisionModelLoadCompletion)handler;

- (instancetype)initWithModel:(MLModel *)mlModel;

- (IMPDecision *)chooseFrom:(NSArray *)variants;

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants given:(nullable NSDictionary <NSString *, id>*)givens;

- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens;

@end

NS_ASSUME_NONNULL_END
