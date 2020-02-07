//
//  IMPMatrixBatchProvider.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/6/20.
//

#import <CoreML/CoreML.h>

@class IMPMatrix;

NS_ASSUME_NONNULL_BEGIN

/**
 Provides features with names made of prefix and index. Wraps double features into MLFeatureProvider.
 Returns nil for NAN features. NAN indicates that feature is missing, this is not the same as 0.
 */
@interface IMPMatrixBatchProvider : NSObject<MLBatchProvider>

@property(readonly, nonatomic) IMPMatrix *matrix;

/// The default value is "f"
@property(copy, nonatomic) NSString *featureNamePrefix;

- (instancetype)initWithMatrix:(IMPMatrix *)matrix;

@end

NS_ASSUME_NONNULL_END
