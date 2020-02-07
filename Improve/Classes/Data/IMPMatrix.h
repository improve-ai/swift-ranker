//
//  IMPMatrix.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/5/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// An Objective-C wrapper for matrix of double numbers. Supports ARC memory management.
@interface IMPMatrix : NSObject

@property(readonly, nonatomic) NSUInteger rows;

@property(readonly, nonatomic) NSUInteger columns;

/// Row major index order.
@property(readonly, nonatomic) double *buffer;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithRows:(NSUInteger)rows columns:(NSUInteger)columns
NS_DESIGNATED_INITIALIZER;

- (double)valueAtRow:(NSUInteger)row column:(NSUInteger)column;

- (void)setValue:(double)value atRow:(NSUInteger)row column:(NSUInteger)column;

/// Returns a new 2D array of NSNumbers. Row-major.
- (NSArray *)aNSArray;

@end

NS_ASSUME_NONNULL_END
