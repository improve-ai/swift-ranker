//
//  Improve.h
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"

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
/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param modelName The name of the trained model to use when choosing variants.
 @param iterationCount How many times the new properties should be extracted.
 @param properties Properties which were chosen by `chose` function from the variants with the same
 model and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error with the model.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                         model:(NSString *)modelName
                       context:(NSDictionary *)context
              chosenProperties:(NSDictionary *)properties
                iterationCount:(NSUInteger)iterationCount;

/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 iterationCount is set to 9 by default.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param modelName The name of the trained model to use when choosing variants.
 @param properties Properties which were chosen by `chose` function from the variants with the same
 model and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error with the model.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                         model:(NSString *)modelName
                       context:(NSDictionary *)context
              chosenProperties:(NSDictionary *)properties;

@end
