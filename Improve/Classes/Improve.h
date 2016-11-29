//
//  Improve.h
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016 Impressive Sounding, LLC. All rights reserved.
//

/**
 Wrapper library for the improve.ai JSON/HTTP API.
 
 For docs see https://improve.ai/
 */
@interface Improve : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *userId;

/**
 Get the current singleton.
 */
+ (Improve *)sharedInstance;

/**
 Initialize the singleton
 
 @param apiKey The improve.ai api key
 */
+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey;
/**
 Initialize the singleton

 @param apiKey The improve.ai api key
 @param userId The unique id for this user so that their events can be tracked through the funnel
 */
+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId;

/**
 Track an event.

 @param properties A dictionary of properties.  improve.ai will learn which property values maximize the funnel conversion probability.
 */
- (void)track:(NSString *)event properties:(NSDictionary *)properties;

/**
 Choose a value for the given property key that might maximize the probability of a funnel conversion.  If there is little data about a given property value, then improve.ai may choose to that value in order to learn more.
 
 @param choices An array of possible values for the property
 @param forKey The property key to optimize for
 @param funnel The funnel to maximize the conversion rate of
 @param block A block to be executed when the response is returned.
 */
- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSString *, NSError *)) block;

/**
 Choose a value for the given property key that might maximize the probability of a funnel conversion.  If there is little data about a given property value, then improve.ai may choose to that value in order to learn more.
 
 @param choices An array of possible values for the property
 @param forKey The property key to optimize for
 @param funnel The funnel to maximize the conversion rate of
 @param rewards An array of rewards to weight the conversion probability of a choice against.  The reward is effectively multiplied by the conversion probability and the choice that maximizes that multiple will tend to be chosen.
 @param block A block to be executed when the response is returned.
 */
- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel rewards:(NSArray *)rewards block:(void (^)(NSString *, NSError *)) block;

/**
 Sort the choices for the given property key by their probability of a funnel conversion.  If there is little data about a given property value, then improve.ai may prioritize that value in order to learn more.
 
 @param choices An array of possible values to be sorted
 @param forKey The property key to optimize for
 @param funnel The funnel to maximize the conversion rate of
 @param rewards An array of rewards to weight the conversion probability of a choice against.  The reward is effectively multiplied by the conversion probability and the choice that maximizes that multiple will tend to be chosen.
 @param block A block to be executed when the response is returned.
 
 @discussion In the track methods, the property value most only take one value from the list of choices at a time.  Tracking an event with the entire choice list as the property value will not work.
 */
- (void)sort:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block;


@end

