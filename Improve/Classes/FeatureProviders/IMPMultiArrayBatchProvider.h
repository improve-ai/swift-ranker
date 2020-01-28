//
//  IMPMultiArrayBatchProvider.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/27/20.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Takes the 2D MLMultiArray. Provides batch access to features. Rows are wrapped in MLFeatureProvider which provides access
 to the row elements by names: "f0", "f1", ....
 */
@interface IMPMultiArrayBatchProvider: NSObject<MLBatchProvider>

@property(readonly, nonatomic) MLMultiArray *multiArray;

- (instancetype)initWithArray:(MLMultiArray *)multiArray;

@end

NS_ASSUME_NONNULL_END
