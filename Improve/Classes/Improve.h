//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

extern NSNotificationName const ImproveDidLoadModelNotification;

typedef void (^IMPTrackCompletion) (NSError *_Nullable error);

@interface Improve : NSObject

/// true if the model is loaded and ready to make choices, false otherwise
@property (readonly) BOOL isReady;

@property (atomic, strong) NSString *modelBundleUrl;

@property (atomic, strong) NSString *apiKey;

@property (atomic, strong) NSString *trackUrl;

@property (atomic, strong) NSString *chooseUrl;

/// This probability affects how often "variants" input is tracked. Should be within [0, 1]. The default is 0.01.
@property (atomic, assign) double trackVariantsProbability;

/**
 How many times will each choose() be run in a low priority thread to calculate the propensity score?
 Lower numbers reduce CPU/energy use.  Default is 10. Set to <= 1 to disable.
 */
@property (atomic, assign) int propensityScoreTrialCount;

/**
 Max stale age of the cached models. If the cached models has expired, the new ones will be requested soon.
 The default value is 604800 (1 week).
 */
@property (atomic, assign) NSTimeInterval maxModelsStaleAge;

/**
 @return The dfeault singleton.
 */
+ (Improve *) instance;

+ (Improve *) instanceWithName:(NSString *)name;

/**
 Perform required initialization. You should call this on the instance before using it.
 Good place to initialize instances is `didFinishLaunchingWithOptions` method of UIApplicationDelegate.
 You should call this only once, consequentive calls will be ignored.
 */
- (void) initializeWithApiKey:(NSString *)apiKey modelBundleURL:(NSString *)urlStr;

/**
 Adds block which is invoked when the model is loaded and ready to make choices. Block is executed synchronously
 if model is loaded.
 @param block A block to invoke when model is ready.
 */
- (void) onReady:(void (^)(void)) block;

/**
 Chooses a variant that is expected to maximize future rewards. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param namespaceStr A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs. If model is not ready, immediately returns the first variant.
 */
- (id) choose:(NSString *) namespaceStr
     variants:(NSArray *) variants;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param namespaceStr A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs.  If model is not ready, immediately returns the first variant.
*/
- (id) choose:(NSString *) namespaceStr
     variants:(NSArray *) variants
      context:(NSDictionary *) context;

/**
 Sorts variants from largest to smallest expected future rewards.
 
 @param namespaceStr A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSString *) namespaceStr
          variants:(NSArray *) variants;

/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.
 
 @param namespaceStr A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSString *) namespaceStr
          variants:(NSArray *) variants
           context:(NSDictionary *) context;


/**
 EXPERIMENTAL: Let us know at support@improve.ai if you're using this.  I'm not sure if remote choose flows with this library.
 */
- (void) chooseRemote:(NSString *) namespaceStr
           variants:(NSArray *) variants
            context:(NSDictionary *) context
         completion:(void (^)(id, NSError *)) block;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespaceStr A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 */
- (void) trackDecision:(NSString *) namespaceStr
               variant:(id) variant;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespaceStr A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
*/
- (void) trackDecision:(NSString *) namespaceStr
               variant:(id) variant
               context:(nullable NSDictionary *) context;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespaceStr A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
*/
- (void) trackDecision:(NSString *) namespaceStr
               variant:(id) variant
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespaceStr A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
 @param completionHandler Called after sending the decision to the server.
 */
- (void) trackDecision:(NSString *) namespaceStr
               variant:(id) variant
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey
            completion:(nullable IMPTrackCompletion) completionHandler;

/**
 Tracks a reward value for one or more chosen variants. Rewards are additive by default. Multiple chosen variants can be listening for the same reward key
 @param reward a JSON encodeable reward vaue to add to recent chosen variants for rewardKey.  May be a negative number.  Must not be NaN or infinity.
 @param rewardKey the namespace or custom rewardKey to track this reward for.
 */
- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey;

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
*/
- (void) addRewards:(NSDictionary<NSString *, NSNumber *> *) rewards;

/**
 Tracks rewards for one or more chosen variants. Rewards are additive by default.  Multiple chosen variants can be listening for the same reward key.
 @param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
 @param completionHandler Called after sending the rewards.
*/
- (void) addRewards:(NSDictionary<NSString *, NSNumber *> *) rewards
         completion:(nullable IMPTrackCompletion) completionHandler;

/**
 I'm contemplating adding a $set mode to rewards to allow non-accumulating rewards such as binary rewards.
 */
// - (void) trackRewards:(NSDictionary *)rewards mode:(ImproveRewardsMode *)mode;

/**
 Tracks a general analytics event that may be further processed by backend scripts.  You may use this for example to keep reward assignment logic on the backend.  In the case where all reward logic is handled on the backend you may wish to disable autoTrack on choose calls and not call trackRewards.
 @param event the name of the event to track
 @param properties JSON encodable event properties
 */
- (void) trackAnalyticsEvent:(NSString *) event
                  properties:(NSDictionary *) properties;

/**
 Tracks a general analytics event that may be further processed by backend scripts.  You may use this for example to keep reward assignment logic on the backend.  In the case where all reward logic is handled on the backend you may wish to disable autoTrack on choose calls and not call trackRewards.
 @param event the name of the event to track
 @param properties JSON encodable event properties
 @param context JSON encodeable context
 */
- (void) trackAnalyticsEvent:(NSString *) event
                  properties:(NSDictionary *) properties
                     context:(nullable NSDictionary *) context;

@end

NS_ASSUME_NONNULL_END
