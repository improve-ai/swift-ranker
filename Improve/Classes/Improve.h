//
//  Improve.h
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016-2017 Impressive Sounding, LLC. All rights reserved.
//

/**
 Wrapper library for the improve.ai JSON/HTTP API.
 
 For docs see https://docs.improve.ai/
 */
@interface Improve : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *chooseUrl;
@property (nonatomic, strong) NSString *trackUrl;
@property (nonatomic, strong) NSString *usingUrl;
@property (nonatomic, strong) NSString *rewardsUrl;

/**
 Get the current singleton.
 */
+ (Improve *)instance;

/**
 Initialize the singleton
 
 @param apiKey The improve.ai api key
 */
+ (Improve *)instanceWithApiKey:(NSString *)apiKey;
/**
 Initialize the singleton

 @param apiKey The improve.ai api key
 @param userId The unique id for this user so that their events can be tracked
 */
+ (Improve *)instanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId;

/**
 Track that one or more properties are being used/causal.
 
 @param properties A dictionary of properties that are causal
 */
- (void) trackUsing:(NSDictionary *)properties;

/**
 Track that the use of one or more properties led to a successful result.
 
 @param properties A dictionary of properties that led to a successful result
 */
- (void) trackSuccess:(NSDictionary *)properties;

- (void) trackRevenue:(NSNumber *)revenue;

- (void) trackRevenue:(NSNumber *)revenue currency:(NSString *)currency;

- (void) trackRewards:(NSDictionary *)rewards;

- (void) trackRewards:(NSDictionary *)rewards currency:(NSString *)currency;

/**
 Track an event.

 @param properties A dictionary of properties that are causal on this event
 */
- (void) track:(NSString *)event properties:(NSDictionary *)properties;

/**
 Resolve an improve.yml configuration file using improve.ai
 
 @param fetchRequest A URLRequest used to retrieve the improve.yml file
 @param block A block to be executed on the main queue when the response is returned.
 */
- (void) choose:(NSURLRequest *)fetchRequest block:(void (^)(NSDictionary *, NSError *)) block;

/**
 Choose a variant for each property.
 
 @param variants A mapping from property key to an NSArray of potential variants to choose from
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
- (void) chooseFrom:(NSDictionary *)variants block:(void (^)(NSDictionary *, NSError *)) block;

/**
 Choose a variant for each property.
 
 @param variants A mapping from property key to an NSArray of potential variants to choose from
 @param config An improve.ai variant configuration following the format of the variant_config stanza detailed at https://docs.improve.ai
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
- (void) chooseFrom:(NSDictionary *)variants withConfig:(NSDictionary *)config block:(void (^)(NSDictionary *, NSError *)) block;

@end

