//
//  Improve.h
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"
#import "IMPDelegate.h"

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

/**
 Choose a variant for each property.  It is the callers responsibility to call trackUsing: once when the returned properties are used
 
 @param variants A mapping from property keys to NSArrays of potential variants to choose from
 @param action A rewardable action associated with the choosing
 @param context Additional parameters added to each variant
 @param chooseURL Remote service URL
 @param block A block to be executed on the main queue when the response is returned, containing an NSDictionary mapping property keys to their chosen values
 */
- (void) chooseRemote:(NSDictionary *)variants
               action:(NSString *)action
              context:(NSDictionary *)context
                  url:(NSURL *)chooseURL
           completion:(void (^)(NSDictionary *, NSError *)) block
DEPRECATED_ATTRIBUTE;

/**
 Chooses a variant for each properties. The variants are chosen according to the model predictions.
 The model corresponding to the specified action is trained and used automatically.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param action A rewardable action associated with the choosing.
 @return A NSDictionary where keys are properties, and the values are single objects choosen from variants.
 */
- (NSDictionary *) choose:(NSDictionary *)variants
                   action:(NSString *)action
                  context:(NSDictionary *)context;

/**
 Choses a single property for the specified key. The same as calling choose with
 {propertyKey: propertyValues} variants dictionary.

 @param propertyValues An array of possible variants which may be property values.
 @param propertyKey A key describing the subject of choosing.
 @param action A rewardable action associated with the choosing.
 @param context A NSDictionary where keys are properties, and the values are single objects choosen from variants.
 */
- (id) choose:(NSArray *)propertyValues
       forKey:(NSString *)propertyKey
       action:(NSString *)action
      context:(NSDictionary *)context;

- (void) track:(NSString *)event properties:(NSDictionary *)properties;

- (void) track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *) rank:(NSArray<NSDictionary*> *)variants
                           action:(NSString *)action
                          context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *) rankAllPossible:(NSDictionary<NSString*, NSArray*> *)variantMap
                                       action:(NSString *)action
                                     context:(NSDictionary *)context;
/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param action A rewardable action associated with the choosing
 @param iterationCount How many times the new properties should be extracted.
 @param properties Properties which were chosen by `chose` function from the variants with the same
 action and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                        action:(NSString *)action
                       context:(NSDictionary *)context
              chosenProperties:(NSDictionary *)properties
                iterationCount:(NSUInteger)iterationCount;

/**
 The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
 the initially chosen properties is chosen overall.

 iterationCount is set to 9 by default.

 @param variants  A mapping from property keys to NSArrays of potential variants to choose from.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @param action A rewardable action associated with the choosing
 @param properties Properties which were chosen by `chose` function from the variants with the same
 action and context.

 @returns The propensity value [0, 1.0], or -1 if there was an error.
 */
- (double) calculatePropensity:(NSDictionary *)variants
                        action:(NSString *)action
                       context:(NSDictionary *)context
              chosenProperties:(NSDictionary *)properties;

@end
