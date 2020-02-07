//
//  NSArray+Multidimensional.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/24/20.
//

#import "NSArray+Multidimensional.h"

@implementation NSArray (Multidimensional)

- (id)objectForKeyedSubscript:(NSArray<NSNumber*> *)subscript
{
    id object = [self objectAtIndex:[subscript.firstObject integerValue]];
    if (subscript.count > 1) {
        NSMutableArray *mutableSubscript = [subscript mutableCopy];
        [mutableSubscript removeObjectAtIndex:0];
        return [self objectForKeyedSubscript:mutableSubscript];
    } else {
        return object;
    }
}

- (NSArray *)flat {
    NSMutableArray *output = [NSMutableArray new];
    for (id object in self) {
        if ([object isKindOfClass:[NSArray class]]) {
            NSArray *subarray = object;
            [output addObjectsFromArray:[subarray flat]];
        } else {
            [output addObject:object];
        }
    }
    return output;
}

- (BOOL)isEqualToArrayRough:(NSArray *)other precision:(double)precision
{
    NSArray *arr1 = [self copy];
    NSArray *arr2 = [other copy];

    if (arr1.count != arr2.count) {
        return false;
    }

    for (NSInteger i = 0; i < arr1.count; i++) {
        id obj1 = arr1[i], obj2 = arr2[i];

        if ([obj1 isKindOfClass:[NSArray class]] && [obj2 isKindOfClass:[NSArray class]]) {
            if (![(NSArray *)obj1 isEqualToArrayRough:(NSArray *)obj2 precision:precision]) {
                return false;
            }
        }

        if ([obj1 isKindOfClass:[NSNumber class]] && [obj2 isKindOfClass:[NSNumber class]]) {
            if (ABS([obj1 doubleValue] - [obj2 doubleValue]) > precision) {
                return false;
            }
        }

        if (![obj1 isEqual:obj2]) {
            return false;
        }
    }
    return true;
}

- (BOOL)isEqualToArrayRough:(NSArray *)other {
    return [self isEqualToArrayRough:other precision:0.001];
}

@end
