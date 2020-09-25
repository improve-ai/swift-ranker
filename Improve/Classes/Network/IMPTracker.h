//
//  IMPTracker.h
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^IMPTrackCompletion) (NSError *_Nullable error);

@interface IMPTracker : NSObject

@property(nonatomic, strong) IMPModelConfiguration *configuration;

- (instancetype) initWithConfiguration:(IMPModelConfiguration *)configuration;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
 @param completionHandler Called after sending the decision to the server.
 */
- (void) trackDecision:(id) variant
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey
            completion:(nullable IMPTrackCompletion) completionHandler;

/**
 Tracks a reward value for one or more chosen variants. Rewards are additive by default. Multiple chosen variants can be listening for the same reward key
 @param reward a JSON encodeable reward vaue to add to recent chosen variants for rewardKey.  May be a negative number.  Must not be NaN or infinity.
 @param rewardKey the namespace or custom rewardKey to track this reward for.
 @param completionHandler Called after sending the reward.
 */
- (void) addReward:(NSNumber *) reward
            forKey:(NSString *) rewardKey
        completion:(nullable IMPTrackCompletion) completionHandler;

/**
 Tracks rewards for one or more chosen variants. Rewards are additive by default.  Multiple chosen variants can be listening for the same reward key.
 @param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
 @param completionHandler Called after sending the rewards.
*/
- (void) addRewards:(NSDictionary<NSString *, NSNumber *> *) rewards
         completion:(nullable IMPTrackCompletion) completionHandler;

@end

NS_ASSUME_NONNULL_END
