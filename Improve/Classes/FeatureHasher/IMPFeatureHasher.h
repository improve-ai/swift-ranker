//
//  IMPFeatureHasher.h
//  FeatureHasher
//
//  Created by Vladimir on 1/16/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

@class IMPModelMetadata;

typedef NSDictionary<NSNumber*, NSNumber*> IMPFeaturesDictT;

NS_ASSUME_NONNULL_BEGIN

/// Implements lookup-table based feature hashing
@interface IMPFeatureHasher : NSObject

@property(nonatomic, readonly) NSArray *table;

@property(nonatomic, assign) uint32_t modelSeed;

@property(nonatomic, readonly) NSUInteger columnCount;

/**
 @param table A lookup table - nested array of NSNumbers.
 @param seed Hashing seed.
 */
- (instancetype)initWithTable:(NSArray *)table seed:(uint32_t)seed NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithMetadata:(IMPModelMetadata *)metadata;

- (instancetype)init NS_UNAVAILABLE;

/**
 Performs flattening and encodes keys and values. Keys are encoded with integer numbers (columns).
 NSNumber values are encoded as double NSNumbers, string values are hashed and replaced with double NSNumbers.
 All other values are skipped.
 @param properties A dictionary with string keys.
 @return A dictionary where keys are columns (NSNumber, integer) and values are double-NSNumbers.
 */
- (IMPFeaturesDictT *)encodeFeatures:(NSDictionary *)properties;

/**
 Same as -encodeFeatures: with {propertyKey: variant} input.
 */
- (IMPFeaturesDictT *)encodePartialFeaturesWithKey:(NSString *)propertyKey
                                           variant:(NSDictionary *)variant;

/**
 Encodes flat dicitonary which shouldn't have nested dictionaries or arrays.
 @return A dictionary where keys are columns (NSNumber, integer) and values are double-NSNumbers.
 */
- (IMPFeaturesDictT *)encodeFeaturesFromFlattened:(NSDictionary *)flattenedProperties;

- (NSArray<IMPFeaturesDictT*> *)batchEncode:(NSArray<NSDictionary*> *)properties;

@end

NS_ASSUME_NONNULL_END
