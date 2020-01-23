//
//  IMPFeatureHasher.h
//  FeatureHasher
//
//  Created by Vladimir on 1/16/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Implements feature hashing, aka the hashing trick.
@interface IMPFeatureHasher : NSObject

/**
 The number of features (columns) in the output matrices. Small numbers of features are likely to cause hash collisions, but large numbers will cause larger coefficient dimensions in linear learners.
 */
@property(nonatomic, readonly) NSUInteger numberOfFeatures;

/**
 When true, an alternating sign is added to the features as to approximately conserve the inner product in the hashed space even for small numberOfFeatues. This approach is similar to sparse random projection.
 */
@property(nonatomic, readonly, getter=shouldAlternateSign) BOOL alternateSign;

/**
 @param numberOfFeatures The number of features (columns) in the output matrices. Small numbers of features are likely to cause hash collisions, but large numbers will cause larger coefficient dimensions in linear learners. Default value: 1048576 (2^20).
 @param alternateSign When true, an alternating sign is added to the features as to approximately conserve the inner product in the hashed space even for small numberOfFeatues. This approach is similar to sparse random projection.
 */
- (instancetype)initWithNumberOfFeatures:(NSUInteger)numberOfFeatures
                           alternateSign:(BOOL)alternateSign NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithNumberOfFeatures:(NSUInteger)numberOfFeatures;

/**
 Recieves an array of samples (dicitionaries) like [{'dog': 1, 'cat':2, 'elephant':4},{'dog': 2, 'run': 5}].
 Values of a dictionary should be either of NSNumber or NSString type. In the last case, the key will be interpreted as
 "key=value" strings and the value will be 1.

 @return A 2D matrix of size numberOfSamples x numberOfFeatures.
 */
- (NSArray<NSArray<NSString*>*> *)transform:(NSArray<NSDictionary<NSString*,id>*> *)x;

@end

NS_ASSUME_NONNULL_END
