//
//  Improve.h
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

@interface Improve : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *chooseUrl;
@property (nonatomic, strong) NSString *trackUrl;

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
- (void) chooseRemote:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block;

/**
 Choses a variant for each properties. The variants are chosen according to the model predictions.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param modelName The name of the trained model to use when choosing variants.
 @return A NSDictionary where keys are properties, and the values are single objects choosen from variants.
 */
- (NSDictionary *) choose:(NSDictionary *)variants
                    model:(NSString *)modelName
                  context:(NSDictionary *)context;

- (void) track:(NSString *)event properties:(NSDictionary *)properties;

- (void) track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *) rank:(NSArray<NSDictionary*> *)variants
                            model:(NSString *)modelName
                          context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *) rankAllPossible:(NSDictionary<NSString*, NSArray*> *)variantMap
                                       model:(NSString *)modelName
                                     context:(NSDictionary *)context;

@end
