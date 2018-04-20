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

// PRIVATE
@property (nonatomic, strong) NSMutableDictionary *propertiesByModel;
@property (nonatomic, strong) NSMutableDictionary *contextByModel;
@property (nonatomic, strong) NSMutableDictionary *usingByModel;

/**
 Get the current singleton.
 */
+ (Improve *) instance;

/**
 Initialize the singleton
 
 @param apiKey The improve.ai api key
 */
+ (Improve *) instanceWithApiKey:(NSString *)apiKey;
/**
 Initialize the singleton

 @param apiKey The improve.ai api key
 @param userId The unique id for this user so that their events can be tracked
 */
+ (Improve *) instanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId;

/**
 Choose a variant for each property.  It is the callers responsibility to call trackUsing: once when the returned properties are used
 
 @param variants A mapping from property keys to NSArrays of potential variants to choose from
 @param modelName The name of the trained model to use when choosing variants
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
- (void) choose:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block;

//- (void) setContextObject:(NSObject *)object forKey:(NSString *)key;

//- (NSDictionary *) context;

/**
 Set the variants for a given model.  Property usage tracking is handled automatically when used in conjunction with propertiesForModel: so don't call
 trackUsing: if you use this method.  A request will be sent to improve.ai to choose a set of properties from those variants.  The resolved properties can be retrieved
 later by calling propertiesForModel:
 
 @param variants A mapping from property keys to NSArrays of potential variants to choose from
 @param model The name of the trained model to use when choosing variants
 */
- (void) setVariants:(NSDictionary *)variants model:(NSString *)model context:(NSDictionary *)context;

/**
 Set the properties for a given model.  Property usage tracking is handled automatically when used in conjunction with propertiesForModel: so don't call
 trackUsing: if you use this method.  The properties can be retrieved
 later by calling propertiesForModel:
 
 @param properties A mapping from property keys to NSArrays of potential variants to choose from
 @param model The name of the model to train
 */
- (void) setProperties:(NSDictionary *)properties model:(NSString *)model context:(NSDictionary *)context;

/**
 Retrieves the resolved properties for a given model.  If this is called before setVariants has recieved a response from improve.ai, then the first variant for each property will be used.
 If this is called before calling setVariants or setProperties, then an empty dictionary will be returned going forward.  trackUsing: is called implicitly the first time
 properties are retrieved for a model.  trackUsing: is skipped if setVariants: or setProperties: aren't called before propertiesForModel:
 @param model The name of the model to train
 */
- (NSDictionary *) propertiesForModel:(NSString *)model;

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

