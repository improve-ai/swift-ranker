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

@end

