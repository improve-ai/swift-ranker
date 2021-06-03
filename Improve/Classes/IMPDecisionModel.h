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

@property(nonatomic, readonly, strong) NSString *modelName;

@property(nonatomic, strong) IMPDecisionTracker *tracker;

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns the synchronously loaded DecisionModel instance.
 Notice that current thread would be blocked until the MLModel is downloaded and compiled.
 @param url A url that can be a  local file path,  a remote http url that points to a MLModel file, or even a bundled MLModel file. Urls that end with '.gz'  are considered gzip compressed, and will be handled appropriately.
 */
+ (nullable instancetype)load:(NSURL *)url error:(NSError **)error;

/**
 @param url A url that can be a  local file path,  a remote http url that points to a MLModel file, or even a bundled MLModel file. Urls that end with '.gz'  are considered gzip compressed, and will be decompressed automatically.
 */
- (void)loadAsync:(NSURL *)url completion:(IMPDecisionModelLoadCompletion)handler;

- (instancetype)initWithModelName:(NSString *)modelName NS_SWIFT_NAME(init(_:));

/**
 Chainable way to set the tracker that returns self
 */
- (instancetype)track:(IMPDecisionTracker *)tracker;

/**
 Returns a IMPDecision object to be lazily evaluated
 @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, nulls, and booleans.
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants given:(nullable NSDictionary <NSString *, id>*)givens;

/**
 Returns a IMPDecision object to be lazily evaluated
 */
- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens;

/**
 Returns a list of the variants ranked from best to worst
 */
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

@end

NS_ASSUME_NONNULL_END
