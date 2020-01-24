//
//  NSArray+Multidimensional.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/24/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (Multidimensional)

/// Similar to -[MLMultiArray objectForKeyedSubscript:];
- (id)objectForKeyedSubscript:(NSArray<NSNumber*> *)subscript;

/// @return Returns a flattened copy
- (NSArray *)flat;

/// Compare multidimensional numeric arrays with given precision. Regular objects are compared using -isEqual:.
- (BOOL)isEqualToArrayRough:(NSArray *)other precision:(double)precision;
- (BOOL)isEqualToArrayRough:(NSArray *)other;

@end

NS_ASSUME_NONNULL_END
