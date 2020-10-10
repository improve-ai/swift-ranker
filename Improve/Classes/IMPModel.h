//
//  Improve.h
//
//  Created by Choosy McChooseFace on 9/8/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPModel : NSObject

/**
 The name of the Improve model from the MLModel metadata - used for tracking and training
 */
@property (atomic, readonly) NSString *modelName;

@property (nonatomic, strong) MLModel *model;

+ (void)modelWithContentsOfURL:(NSURL *)url
                   cacheMaxAge:(NSInteger) cacheMaxAge
             completionHandler:(void (^)(IMPModel * _Nullable model, NSError * _Nullable error))handler;

- (instancetype) initWithModel:(MLModel *) mlModel;

/**
 Chooses a variant that is expected to maximize future rewards. Call `-trackDecision:` and
 `-addReward:` in order to train the model after choosing.

 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs. If model is not ready, immediately returns the first variant.
 */
- (id) choose:(NSArray *) variants;

/**
 Chooses a variant that is expected to maximize future rewards for the given context. Call `-trackDecision:` and
 `-addReward:` in order to train the model after choosing.

 @param variants  A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that choose should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return The chosen variant, which may be different between calls even with the same inputs.  If model is not ready, immediately returns the first variant.
*/
- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context;

/**
 Sorts variants from largest to smallest expected future rewards.

 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSArray *) variants;

/**
 Sorts variants from largest to smallest expected future rewards for the given context.  None of the variants will be tracked, so no learning will take place unless trackChosen, or choose with autoTrack enabled, are called.

 @param variants  A JSON encodeable list of variants to sort.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A JSON encodeable dictionary of key value pairs that describe the context that sort should be optimized for. May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @return A sorted copy of the variants array from largest to smallest expected future rewards, which may be different between calls even with the same inputs.  If model is not ready, immediately returns a shallow unsorted copy of the variants.
*/
- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context;

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray *) score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *) score:(NSArray *)variants
            context:(nullable NSDictionary *)context;


@end

NS_ASSUME_NONNULL_END
