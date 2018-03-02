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
 Choose a variant for each property.
 
 @param variants A mapping from property keys to NSArrays of potential variants to choose from
 @param modelName The name of the trained model to use when choosing variants
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
- (void)choose:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block;

/**
 Track that one or more properties are being used/causal.
 
 @param properties A dictionary of properties that are causal
 */
- (void) trackUsing:(NSDictionary *)properties model:(NSString *)modelName context:(NSDictionary *)context;

- (void) trackUsing:(NSDictionary *)properties model:(NSString *)modelName context:(NSDictionary *)context rewardKey:(NSString *)rewardKey;

- (void) trackRevenue:(NSNumber *)revenue receipt:(NSData *)receipt;

- (void) trackRevenue:(NSNumber *)revenue receipt:(NSData *)receipt currency:(NSString *)currency;

- (void) trackRewards:(NSDictionary *)rewards;

- (void) trackRewards:(NSDictionary *)rewards receipt:(NSData *)receipt currency:(NSString *)currency;


@end

