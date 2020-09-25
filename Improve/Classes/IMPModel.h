//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//
#import "IMPModelConfiguration.h"
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPModel : NSObject

/**
 The name of the Improve model from the MLModel metadata - used for tracking and training
 */
@property (nonatomic, readonly) NSString *modelName;

@property (atomic, strong) IMPModelConfiguration *configuration;
@property (atomic, strong) MLModel *mlModel;

+ (void)modelWithContentsOfURL:(NSURL *)url
            configuration:(IMPModelConfiguration *)configuration
        completionHandler:(void (^)(IMPModel *model, NSError *error))handler;

- (instancetype) initWithMLModel:(MLModel *) mlModel configuration:(IMPModelConfiguration *)configuration;

/**
 Chooses a variant that is expected to maximize future rewards. Call `-trackDecision:` and
 `-addReward:` in order to train the model after choosing.

 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs. If model is not ready, immediately returns the first variant.
 */
- (id) choose:(NSArray *) variants;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. Call `-trackDecision:` and
 `-addReward:` in order to train the model after choosing.

 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs.  If model is not ready, immediately returns the first variant.
*/
- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context;

/**
 Sorts variants from largest to smallest expected future rewards.

 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSArray *) variants;

/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.

 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 */
- (void) trackDecision:(id) variant;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.

 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
*/
- (void) trackDecision:(id) variant
               context:(nullable NSDictionary *) context;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
*/
- (void) trackDecision:(id) variant
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey;

/**
 Tracks a reward value for one or more chosen variants. Rewards are additive by default. Multiple chosen variants can be listening for the same reward key
 @param reward a JSON encodeable reward vaue to add to recent chosen variants for rewardKey.  May be a negative number.  Must not be NaN or infinity.
 @param rewardKey the namespace or custom rewardKey to track this reward for.
 */
- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey;

/**
Tracks rewards for one or more chosen variants. Rewards are additive by default.  Multiple chosen variants can be listening for the same reward key.
@param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
*/
- (void) addRewards:(NSDictionary<NSString *, NSNumber *> *) rewards;

@end

NS_ASSUME_NONNULL_END
