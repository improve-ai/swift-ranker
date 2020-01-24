//
//  MLMultiArray+NSArray.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/24/20.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLMultiArray (NSArray)

- (instancetype)initWithArray:(NSArray *)array type:(MLMultiArrayDataType)type;

- (NSArray *)NSArray;

@end

NS_ASSUME_NONNULL_END
