//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

extern NSNotificationName const ImproveDidLoadModelNotification;

@interface Improve : NSObject

@property (atomic, assign) BOOL isReady;
@property (atomic, strong) NSString *modelBundleUrl;
@property (atomic, strong) NSString *apiKey;
@property (atomic, strong) NSString *trackUrl;
@property (atomic, strong) NSString *chooseUrl;

/// This probability affects how often "variants" input is tracked. Should be within [0, 1]. The default is 0.01.
@property (atomic, assign) double trackVariantsProbability;

/**
 @return the current singleton.
 */
+ (Improve *) instance;

/**
 Initialize the singleton
 
 @param apiKey The improve.ai api key
 */
+ (Improve *) instanceWithApiKey:(NSString *)apiKey;

/**
 @return true if the model is loaded and ready to make choices, false otherwise
 */
- (BOOL) isReady;

/**
 @param block invoked when the model is loaded and ready to make choices
 */
- (void) onReady:(void (^)(void)) block;

/**
 Chooses a variant that is expected to maximize future rewards. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param namespace A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs
 */
- (id) choose:(NSString *) namespace
     variants:(NSArray *) variants;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param namespace A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs
*/
- (id) choose:(NSString *) namespace
     variants:(NSArray *) variants
      context:(NSDictionary *) context;

/**
 Sorts variants from largest to smallest expected future rewards.
 
 @param namespace A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs
*/
- (NSArray *) sort:(NSString *) namespace
          variants:(NSArray *) variants;

/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.
 
 @param namespace A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs
*/
- (NSArray *) sort:(NSString *) namespace
          variants:(NSArray *) variants
           context:(NSDictionary *) context;


/**
 EXPERIMENTAL: Let us know at support@improve.ai if you're using this.  I'm not sure if remote choose flows with this library.
 */
- (void) chooseRemote:(NSString *) namespace
           variants:(NSArray *) variants
            context:(NSDictionary *) context
         completion:(void (^)(id, NSError *)) block;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespace A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 */
- (void) trackDecision:(NSString *) namespace
               variant:(id) variant;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespace A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
*/
- (void) trackDecision:(NSString *) namespace
               variant:(id) variant
               context:(NSDictionary *) context;

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param namespace A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
*/
- (void) trackDecision:(NSString *) namespace
               variant:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey;

/**
 Tracks a reward value for one or more chosen variants. Rewards are additive by default. Multiple chosen variants can be listening for the same reward key.
 @param rewardKey the namespace or custom rewardKey to track this reward for.
 @param reward a JSON encodeable reward vaue to add to recent chosen variants for rewardKey.  May be a negative number.  Must not be NaN or infinity.
 */
- (void) trackReward:(NSString *) rewardKey
               value:(NSNumber *) reward;

/**
Tracks rewards for one or more chosen variants. Rewards are additive by default.  Multiple chosen variants can be listening for the same reward key.
@param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
*/
- (void) trackRewards:(NSDictionary<NSString *, NSNumber *> *) rewards;

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
 @param decisions optional decisions (chosen events) to attach to this event.  Some analytics events may infer information about multiple variants that are chosen, for example a screen may have a number of textual elements that were chosen but tracked together as a single element. decision dictionaries are the same format as the trackChosen wire format.
 @param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
*/

- (void) trackAnalyticsEvent:(NSString *) event
                  properties:(NSDictionary *) properties
             attachDecisions:(NSArray<NSDictionary *> *) decisions
               attachRewards:(NSDictionary *) rewards;

@end
