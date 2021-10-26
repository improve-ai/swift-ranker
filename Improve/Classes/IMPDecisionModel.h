//
//  IMPDecisionModel.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

@class IMPDecision;
@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionModel)
@interface IMPDecisionModel : NSObject

@property(class) NSURL *defaultTrackURL;

@property(atomic, strong) NSURL *trackURL;

@property(atomic, strong) MLModel *model;

@property(nonatomic, readonly, strong) NSString *modelName;

- (instancetype)init NS_UNAVAILABLE;

/**
 Returns the synchronously loaded DecisionModel instance.
 Notice that current thread would be blocked until the MLModel is downloaded and compiled.
 @param url A url that can be a  local file path,  a remote http url that points to a MLModel file, or even a bundled MLModel file. Urls that end with '.gz'  are considered gzip compressed, and will be handled appropriately.
 */
+ (nullable instancetype)load:(NSURL *)url error:(NSError **)error;

/**
 * @param url A url that can be a  local file path,  a remote http url that
 * points to a MLModel file, or even a bundled MLModel file. Urls that end
 * with '.gz'  are considered gzip compressed, and will be decompressed automatically.
 */
- (void)loadAsync:(NSURL *)url completion:(void (^)(IMPDecisionModel *_Nullable loadedModel, NSError *_Nullable error))handler;

/**
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one.
 * @exception NSInvalidArgumentException in case of an invalid modelName
 */
- (instancetype)initWithModelName:(NSString *)modelName NS_SWIFT_NAME(init(_:));

- (instancetype)initWithModelName:(NSString *)modelName trackURL:(nullable NSURL *)trackURL NS_SWIFT_NAME(init(_:_:));

/**
 Returns a IMPDecision object to be lazily evaluated
 @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, nulls, and booleans.
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants given:(nullable NSDictionary <NSString *, id>*)givens;

/**
 Returns a IMPDecision object to be lazily evaluated
 */
- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens;

/**
 Adds the reward value to the most recent Decision for this model name for this installation. The most recent Decision can be from a different DecisionModel instance or a previous session as long as they have the same model name.
 If no previous Decision is found, the reward will be ignored.
 @param reward the reward to add. Must not be NaN, positive infinity, or negative infinity
 */
- (void)addReward:(double) reward;

/**
 Returns a list of the variants ranked from best to worst
 @warning This method is likely to be changed in the future. Try not to use it in your code.
 */
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

@end

NS_ASSUME_NONNULL_END
