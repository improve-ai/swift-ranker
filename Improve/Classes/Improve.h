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

// - (id) choose:(NSArray *)variants
// - (id) choose:(NSArray *)variants context:(NSDictionary *)context
// - (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain;
// - (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain rewardKey:(NSString *)rewardKey;
// - (id) choose:(NSArray *)variants context:(NSDictionary *)context domain:(NSString *)domain autoTrack:(BOOL)autoTrack; // public interface should have autoTrack and rewardKey mutually exclusive

/**
 Chooses a variant for each properties. The variants are chosen according to the model predictions.
 The model corresponding to the specified domain is trained and used automatically.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param domain A rewardable domain associated with the choosing.
 @return A NSDictionary where keys are properties, and the values are single objects choosen from variants.
 */
- (NSDictionary *) choose:(NSDictionary *)variants
                  context:(NSDictionary *)context
                   domain:(NSString *)domain;

// - (NSArray *) sort:(NSArray *)variants
// - (NSArray *) sort:(NSArray *)variants context:(NSDictionary *)context

- (NSArray<NSDictionary*> *) sort:(NSArray<NSDictionary*> *)variants
                          context:(NSDictionary *)context
                           domain:(NSString *)domain;

/**
 Choose a variant for each property.  It is the callers responsibility to call trackUsing: once when the returned properties are used
 
 @param variants A mapping from property keys to NSArrays of potential variants to choose from
 @param domain A rewardable domain associated with the choosing
 @param context Additional parameters added to each variant
 @param chooseURL Remote service URL
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
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
- (void) trackReward:(NSNumber *) reward;
- (void) trackRewards:(NSDictionary *)rewards;

//- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties;
//- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties attachDecisions:(NSArray *)decisions attachRewards:(NSDictionary *)rewards;


/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param domain A rewardable domain associated with the choosing
 @param iterationCount How many times the new properties should be extracted.
 @param chosen The variant that was chosen by `choose` function from the variants with the same
 domain and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                        domain:(NSString *)domain
                       context:(NSDictionary *)context
                        chosen:(NSDictionary *)chosen
                iterationCount:(NSUInteger)iterationCount;

/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 iterationCount is set to 9 by default.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param domain A rewardable domain associated with the choosing
 @param chosen The variant that was chosen by `choose` function from the variants with the same
 domain and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                        domain:(NSString *)domain
                       context:(NSDictionary *)context
                        chosen:(NSDictionary *)chosen;

@end
