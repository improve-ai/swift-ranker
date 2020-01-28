//
//  IMPMultiArrayFeatureProvider.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/27/20.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A wrapper for 2D MLMultiArray allowing access it's values by names. The names consist of prefix + index.
 Indexing is flat, that means the part of the `multiArray` specified by `featuresRange` is treaded as 1D array which starts at `featuresRange.location` in the plain row-major `multiArray` indexing space.
 */
@interface IMPMultiArrayFeatureProvider : NSObject<MLFeatureProvider>

@property(readonly, nonatomic) MLMultiArray *multiArray;

@property(readonly, nonatomic) NSRange featuresRange;

/// The default value is "f"
@property(copy, nonatomic) NSString *prefix;

- (instancetype)initWithArray:(MLMultiArray *)multiArray
                featuresRange:(NSRange)featuresRange;

- (instancetype)initWithArray:(MLMultiArray *)multiArray
                     rowIndex:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
