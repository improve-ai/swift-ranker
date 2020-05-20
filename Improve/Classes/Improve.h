//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"
#import "IMPDelegate.h"

extern NSNotificationName const ImproveDidLoadModelNotification;

@interface Improve : NSObject

@property (nonatomic, strong) NSString *apiKey;

/**
 Get the current singleton.
 */
+ (Improve *) instance;

/**
 Initialize the and configure the singleton. You should call this method before using the Improve.

 @param configuration A configuration containing valid API key.
 */
+ (void) configureWith:(IMPConfiguration *)configuration;

/**
 EXPERIMENTAL: The delegate interface is very likely to change.  Please let us know if you're using it at support@improve.ai.
 */
@property (strong, nonatomic) id<IMPDelegate> delegate;

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
 
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs
 */
- (id) choose:(NSArray *)variants;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs
*/
- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param domain A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.  By default, the rewardKey for the chosen variant is set to be equal to the domain.  If the domain is nil, the domain will be set to @"default_domain" and the rewardKey will also be set to @"default_domain".
 @return The chosen variant, which may be different between calls even with the same inputs
*/
- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
       domain:(NSString *)domain;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. The chosen variant will be automatically tracked to learn from its future rewards so do not call trackChosen.
 
 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param domain A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.  By default, the rewardKey for the chosen variant is set to be equal to the domain.  If the domain is nil, the domain will be set to @"default_domain" and the rewardKey will also be set to @"default_domain".
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the domain.  If the domain is also nil, rewardKey and domain are set to @"default_domain". trackRewards must have this key in its dictionary to assign rewards to this chosen variant.
 @return The chosen variant, which may be different between calls even with the same inputs
*/
- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
       domain:(NSString *)domain
    rewardKey:(NSString *)rewardKey;

/**
  Chooses a variant that is expected to maximize future rewards for the given context.  If autoTrack is false, then the chosen variant will not be automatically tracked.
  
  @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
  @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
  @param domain A descriptor and namespace for the type of variant being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
  @param autoTrack false to disable auto tracking of the chosen variant.  In this case trackChosen should be called later.
  @return The chosen variant, which may be different between calls even with the same inputs
 */
- (id) choose:(NSArray *)variants
      context:(NSDictionary *)context
       domain:(NSString *)domain
    autoTrack:(BOOL)autoTrack;

/**
 Sorts variants from largest to smallest expected future rewards.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.
 
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return Variants sorted from largest to smallest expected future rewards, which may be different between calls even with the same inputs
*/
- (NSArray *) sort:(NSArray *)variants;
/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.
 
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return Variants sorted from largest to smallest expected future rewards, which may be different between calls even with the same inputs
*/
- (NSArray *) sort:(NSArray *)variants
           context:(NSDictionary *)context;

/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.
 
 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param domain A descriptor and namespace for the type of variant being sorted.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.
 @return Variants sorted from largest to smallest expected future rewards, which may be different between calls even with the same inputs
*/
- (NSArray *) sort:(NSArray *)variants
           context:(NSDictionary *)context
            domain:(NSString *)domain;

/**
 EXPERIMENTAL: Let us know at support@improve.ai if you're using this.  I'm not sure if remote choose flows with this library.
 */
- (void) chooseRemote:(NSArray *)variants
              context:(NSDictionary *)context
               domain:(NSString *)domain
                  url:(NSURL *)chooseURL
           completion:(void (^)(id, NSError *)) block;

// TODO document that when domain is nil it is set to "default" and when rewardKey is nil it is set to the domain or "default"
/**
 Track that a variant was chosen so that the system can learn what rewards it receives.  Be ware that calls to choose already automatically track variants unless autoTrack: is set to false.  The domain and rewardKey are set to the default domain.
 @param chosen The JSON encodeable chosen variant to track
 */
- (void) trackChosen:(id)chosen;

/**
 Track that a variant was chosen so that the system can learn from it's future rewards.  Be ware that calls to choose already automatically track variants unless autoTrack: is set to false.  The domain and rewardKey are set to the default domain.
 @param chosen The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose (with autoTrack set to false) or sort.
*/
- (void) trackChosen:(id)chosen
             context:(NSDictionary *)context;

/**
 Track that a variant was chosen so that the system can learn from it's future rewards.  Be ware that calls to choose already automatically track variants unless autoTrack: is set to false.  The domain and rewardKey are set to the default domain.
 @param chosen The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose (with autoTrack set to false) or sort.
 @param domain A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.  By default, the rewardKey for the chosen variant is set to be equal to the domain.  If the domain is nil, the domain will be set to @"default_domain" and the rewardKey will also be set to @"default_domain".
*/
- (void) trackChosen:(id)chosen
             context:(NSDictionary *)context
              domain:(NSString *) domain;

/**
 Track that a variant was chosen so that the system can learn from it's future rewards.  Be ware that calls to choose already automatically track variants unless autoTrack: is set to false.  The domain and rewardKey are set to the default domain.
 @param chosen The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose (with autoTrack set to false) or sort.
 @param domain A descriptor and namespace for the type of variant chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.  By default, the rewardKey for the chosen variant is set to be equal to the domain.  If the domain is nil, the domain will be set to @"default_domain" and the rewardKey will also be set to @"default_domain".
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the domain.  If the domain is also nil, rewardKey and domain are set to @"default_domain".  trackRewards must have this key in its dictionary to assign rewards to this chosen variant.
*/
- (void) trackChosen:(id)chosen
             context:(NSDictionary *)context
              domain:(NSString *) domain
           rewardKey:(NSString *) rewardKey;

/**
 Tracks a reward value for one or more chosen variants.  Use when neither a domain nor a rewardKey were used with choose.  If choose or trackChosen were specified with a domain or rewardKey, then trackRewards:(NSDictionary *) must be used instead. Rewards are additive by default.  This call is equivilent to trackRewards:@{ @"default_domain": reward }]
 @param reward a JSON encodeable reward vaue to add to recent chosen variants in the default domain/default rewardKey.  May be a negative number.  Must not be NaN or infinity.
 */
- (void) trackReward:(NSNumber *) reward; // maybe get rid of this and force domain to be Improve.DefaultDomain

/**
Tracks rewards for one or more chosen variants. The default rewardKey if no reward key or domain is specified is "default_domain". If a domain was specified during the (autoTracked) choose call or trackChosen, then the rewardKey for the chosen variant is its domain. Rewards are additive by default.  Multiple chosen variants can be listening for the same reward key.
@param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
*/
- (void) trackRewards:(NSDictionary<NSString *, NSNumber *> *)rewards;

/**
 I'm contemplating adding a $set mode to rewards to allow non-accumulating rewards such as binary rewards.
 */
// - (void) trackRewards:(NSDictionary *)rewards mode:(ImproveRewardsMode *)mode;

/**
 Tracks a general analytics event that may be further processed by backend scripts.  You may use this for example to keep reward assignment logic on the backend.  In the case where all reward logic is handled on the backend you may wish to disable autoTrack on choose calls and not call trackRewards.
 @param event the name of the event to track
 @param properties JSON encodable event properties
 */
- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties;

/**
 Tracks a general analytics event that may be further processed by backend scripts.  You may use this for example to keep reward assignment logic on the backend.  In the case where all reward logic is handled on the backend you may wish to disable autoTrack on choose calls and not call trackRewards.
 @param event the name of the event to track
 @param properties JSON encodable event properties
 @param decisions optional decisions (chosen events) to attach to this event.  Some analytics events may infer information about multiple variants that are chosen, for example a screen may have a number of textual elements that were chosen but tracked together as a single element. decision dictionaries are the same format as the trackChosen wire format.
 @param rewards a JSON encodeable dictionary mapping rewardKeys to reward values to add to recent chosen variants.  Reward values may be negative numbers, must not be NaN or infinity.
*/

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties attachDecisions:(NSArray<NSDictionary *> *)decisions attachRewards:(NSDictionary *)rewards;

@end
