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

@class IMPDecision;
@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionModel)
@interface IMPDecisionModel : NSObject

@property(class) NSURL *defaultTrackURL;

@property(class, readonly) ModelDictionary *instances;

@property (class, readonly) GivensProvider *defaultGivensProvider;

@property(atomic, strong) NSURL *trackURL;

@property(atomic, strong) MLModel *model;

@property(nonatomic, readonly, strong) NSString *modelName;

@property(strong, nonatomic) GivensProvider *givensProvider;

- (instancetype)init NS_UNAVAILABLE;

/**
 * We suggest to have the defaultTrackURL set on startup before creating any IMPDecisionModel instances.
 *
 * The defaultTrackURL will be used to track decisions. So it's an equivalent of
 *   [[IMPDecisionModel alloc] initWithModelName:modelName trackURL:defaultTrackURL];
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one.
 * @exception NSInvalidArgumentException in case of an invalid modelName
 */
- (instancetype)initWithModelName:(NSString *)modelName NS_SWIFT_NAME(init(_:));

/**
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one.
 * @param trackURL url for tracking decisions. If trackURL is nil, no decisions would be tracked.
 * @exception NSInvalidArgumentException in case of an invalid modelName
 */
- (instancetype)initWithModelName:(NSString *)modelName trackURL:(nullable NSURL *)trackURL NS_SWIFT_NAME(init(_:_:));

/**
 * @param url A url that can be a  local file path,  a remote http url that points to a MLModel file, or even a bundled MLModel file.
 * Urls that end with '.gz'  are considered gzip compressed, and will be handled appropriately.
 * @return A DecisionModel instance with the model specified by the url loaded synchronously.
 */
+ (nullable instancetype)load:(NSURL *)url error:(NSError **)error;

/**
 * @param url A url that can be a  local file path,  a remote http url that
 * points to a MLModel file, or even a bundled MLModel file. Urls that end
 * with '.gz'  are considered gzip compressed, and will be decompressed automatically.
 */
- (void)loadAsync:(NSURL *)url completion:(void (^)(IMPDecisionModel *_Nullable loadedModel, NSError *_Nullable error))handler;

/**
 * @param givens Additional context info that will be used with each of the variants to calcuate the score
 * @return A IMPDecision object to be lazily evaluated
 */
- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens;

- (NSDictionary<NSString *, id> *)givens;

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @return An IMPDecision object to be lazily evaluated
 */
- (IMPDecision *)chooseFrom:(NSArray *)variants NS_SWIFT_NAME(chooseFrom(_:));

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants;

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @param givens Additional context info that will be used with each of the variants to calcuate the score
 * @return scores of the variants
 */
- (NSArray<NSNumber *> *)score:(NSArray *)variants given:(nullable NSDictionary <NSString *, id>*)givens;

/**
 * Adds the reward value to the most recent Decision for this model name for this installation. The most recent Decision
 * can be from a different DecisionModel instance or a previous session as long as they have the same model name.
 * If no previous Decision is found, the reward will be ignored.
 * @param reward the reward to add. Must not be NaN, positive infinity, or negative infinity
 * @exception NSInvalidArgumentException in case of NaN or +-Infinity
 */
- (void)addReward:(double) reward;

/**
 * @warning This method is likely to be changed in the future. Try not to use it in your code.
 * @return a list of the variants ranked from best to worst by scores
 */
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

@end

NS_ASSUME_NONNULL_END
