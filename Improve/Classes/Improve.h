//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"
#import "IMPDelegate.h"

extern NSNotificationName const ImproveDidLoadModelsNotification;

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

@property (strong, nonatomic) id<IMPDelegate> delegate;

- (id) choose:(NSArray *)variants;
- (id) choose:(NSArray *)variants context:(NSDictionary *)context;
/**
Chooses a variant that is expected to maximize future rewards.

@param variants  A list of variants to choose from
@param context A dictionary of key value pairs that describe the context that choose should be optimized for.  It may affect the prediction but is not included in the output.
@param domain A descriptor and namespace for the type of thing being chosen.  It can be simple such as "songs" or "prices" or more complicated such as "SubscriptionViewController.buttonText".  It should be unique within your project to avoid collisions.  By default, the rewardKey is set to be equal to the domain.
@return The chosen variant
*/
- (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain;
- (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain rewardKey:(NSString *)rewardKey;
 // public interface should have autoTrack and rewardKey mutually exclusive
- (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain autoTrack:(BOOL)autoTrack;


//- (NSArray *) sort:(NSArray *)variants;
//- (NSArray *) sort:(NSArray *)variants context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *) sort:(NSArray<NSDictionary*> *)variants
                          context:(NSDictionary *)context
                           domain:(NSString *)domain;

- (void) chooseRemote:(NSArray *)variants
              context:(NSDictionary *)context
               domain:(NSString *)domain
                  url:(NSURL *)chooseURL
           completion:(void (^)(NSDictionary *, NSError *)) block;

// TODO document that when domain is nil it is set to "default" and when rewardKey is nil it is set to the domain or "default"
- (void) trackChosen:(id)chosen;
- (void) trackChosen:(id)chosen context:(NSDictionary *)context;
- (void) trackChosen:(id)chosen context:(NSDictionary *)context domain:(NSString *) domain;
- (void) trackChosen:(id)chosen context:(NSDictionary *)context domain:(NSString *) domain rewardKey:(NSString *) rewardKey;

/**
 Equivilent to trackRewards:@{ @"default": reward }]  Use this when neither a domain nor a rewardKey were used with choose.  An undefined rewardKey defaults to the domain string and an undefined domain defaults to "default".
 */
- (void) trackReward:(NSNumber *) reward; // maybe get rid of this and force domain to be Improve.DefaultDomain
// - (void) trackReward:(NSNumber *) reward domain:(NSString *)domain; forDomain?
- (void) trackRewards:(NSDictionary *)rewards;
// - (void) trackRewards:(NSDictionary *)rewards mode:(ImproveRewardsMode *)mode;

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties;
- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties attachDecisions:(NSArray *)decisions attachRewards:(NSDictionary *)rewards;

/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 @param iterationCount How many times the new properties should be extracted.
 @param chosen The variant that was chosen by the `choose` function function from the variants with the same
 domain and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)chosen
                      variants:(NSDictionary *)variants
                       context:(NSDictionary *)context
                        domain:(NSString *)domain
                iterationCount:(NSUInteger)iterationCount;

/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 iterationCount is set to 9 by default.

 @param domain A rewardable domain associated with the choosing
 @param chosen The variant that was chosen by the `choose` function from the variants with the same
 domain and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)chosen
                      variants:(NSDictionary *)variants
                       context:(NSDictionary *)context
                        domain:(NSString *)domain;

@end
