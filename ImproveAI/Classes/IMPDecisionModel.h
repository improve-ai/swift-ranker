//
//  IMPDecisionModel.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import "Utils/ModelDictionary.h"
#import "Provider/GivensProvider.h"

@class IMPDecisionContext;
@class IMPDecision;
@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionModel)
@interface IMPDecisionModel : NSObject

@property(class) NSURL *defaultTrackURL;

@property(class) NSString *defaultTrackApiKey;

@property(class, readonly) ModelDictionary *instances;

@property (class, readonly) GivensProvider *defaultGivensProvider;

@property(atomic, strong, nullable) NSURL *trackURL;

@property(atomic, copy, nullable) NSString *trackApiKey;

@property(atomic, strong) MLModel *model;

@property(nonatomic, readonly, copy) NSString *modelName;

@property(atomic, strong) GivensProvider *givensProvider;

- (instancetype)init NS_UNAVAILABLE;

/**
 * We suggest to have the defaultTrackURL/defaultTrackApiKey set on startup before creating any IMPDecisionModel instances.
 *
 * The defaultTrackURL/defaultTrackApiKey will be used to track decisions. So it's an equivalent of
 *   [[IMPDecisionModel alloc] initWithModelName:modelName trackURL:defaultTrackURL trackApiKey:defaultTrackApiKey];
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one. 
 * @exception NSInvalidArgumentException in case of an invalid modelName
 */
- (instancetype)initWithModelName:(nonnull NSString *)modelName NS_SWIFT_NAME(init(_:));

/**
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one;
 * @param trackURL url for tracking decisions. If trackURL is nil, no decisions would be tracked.
 * @param trackApiKey will be attached to the header fields of all the post request for tracking
 * @exception NSInvalidArgumentException in case of an invalid modelName
 */
- (instancetype)initWithModelName:(nonnull NSString *)modelName trackURL:(nullable NSURL *)trackURL trackApiKey:(nullable NSString *)trackApiKey NS_SWIFT_NAME(init(_:_:_:));

/**
 * @param url A url that can be a  local file path,  a remote http url that points to a MLModel file, or even a bundled MLModel file.
 * Urls that end with '.gz'  are considered gzip compressed, and will be handled appropriately.
 * @return A DecisionModel instance with the model specified by the url loaded synchronously. If the model failed to load,
 * a nonnull *error will be set and nil is returned.
 */
- (nullable instancetype)load:(NSURL *)url error:(NSError **)error;

/**
 * @param url A url that can be a  local file path,  a remote http url that
 * points to a MLModel file, or even a bundled MLModel file. Urls that end
 * with '.gz'  are considered gzip compressed, and will be decompressed automatically.
 */
- (void)loadAsync:(NSURL *)url completion:(void (^)(IMPDecisionModel *_Nullable loadedModel, NSError *_Nullable error))handler;

/**
 * @param givens Additional context info that will be used with each of the variants to calculate the score
 * @return A IMPDecision object to be lazily evaluated
 */
- (IMPDecisionContext *)given:(NSDictionary <NSString *, id>*)givens NS_SWIFT_NAME(given(_:));

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @return An IMPDecision object.
 * @throws NSInvalidArgumentException Thrown if the variants to choose from is empty or nil
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores NS_SWIFT_NAME(chooseFrom(variants:scores:));

/**
 * This method is an alternative of chooseFrom(). An example here might be more expressive:
 * chooseMutilVariate({"style":["bold", "italic"], "size":[3, 5]})
 *       is equivalent to
 * chooseFrom([
 *      {"style":"bold", "size":3},
 *      {"style":"italic", "size":3},
 *      {"style":"bold", "size":5},
 *      {"style":"italic", "size":5},
 * ])
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity like chooseFrom().
 * The value of the dictionary is expected to be an NSArray. If not, it would be treated as an one-element NSArray anyway.
 * So chooseMultiVariate({"style":["bold", "italic"], "size":3}) is equivalent to chooseMultiVariate({"style":["bold", "italic"], "size":[3]})
 * @return An IMPDecision object.
 * @throws NSInvalidArgumentException Thrown if the variants to choose from is empty or nil
 */
- (IMPDecision *)chooseMultiVariate:(NSDictionary<NSString *, id> *)variants NS_SWIFT_NAME(chooseMultiVariate(_:));

/**
 * This method is a short hand of chooseFrom(variants).get().
 * @param firstVariant If there's only one variant, then the firstVariant must be an NSArray or an NSDictionary.
 * When the only argument is an NSArray, it's equivalent to calling chooseFrom(firstVariant).get();
 * When the only argument is an NSDictionary, it's equivalent to calling chooseMultiVariate(firstVariant).get();
 * When there are two or more arguments, all the arguments would form an NSArray and be passed to chooseFrom()
 * Primitive type arguments are not allowed.
 * @return Returns the chosen variant.
 * @throws NSInvalidArgumentException Thrown if there's only one argument and it's not an NSArray or NSDictionary.
 */
- (id)which:(id)firstVariant, ... NS_REQUIRES_NIL_TERMINATION;

- (id)which:(id)firstVariant args:(va_list)args NS_SWIFT_NAME(which(_:_:));

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @throws NSInvalidArgumentException Thrown if variants is nil or empty.
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants;

/**
 * Adds the reward value to the most recent Decision for this model name for this installation. The most recent Decision
 * can be from a different DecisionModel instance or a previous session as long as they have the same model name.
 * If no previous Decision is found, the reward will be ignored.
 * @param reward the reward to add. Must not be NaN, positive infinity, or negative infinity
 * @throws NSInvalidArgumentException Thrown if reward is NaN or +-Infinity
 */
- (void)addReward:(double) reward;

/**
 * @warning This method is likely to be changed in the future. Try not to use it in your code.
 * @return a list of the variants ranked from best to worst by scores
 */
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

@end

NS_ASSUME_NONNULL_END
