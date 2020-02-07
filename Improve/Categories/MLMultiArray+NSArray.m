//
//  MLMultiArray+NSArray.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/24/20.
//

#import "MLMultiArray+NSArray.h"
#import "NSArray+Padding.h"
#import "NSArray+Multidimensional.h"

@implementation MLMultiArray (NSArray)

- (instancetype)initWithArray:(NSArray *)array type:(MLMultiArrayDataType)type
{
    NSMutableArray *shape = [NSMutableArray new];
    id arrayObject = array;
    while ([arrayObject isKindOfClass:[NSArray class]]) {
        NSArray *dimension = arrayObject;
        [shape addObject:[NSNumber numberWithInteger:dimension.count]];
        arrayObject = dimension[0];
    }
    
    self = [self initWithShape:shape
                      dataType:type
                         error:nil];
    
    [self recursivelyCopyNSArray:array];
    
    return self;
}

/// Assumes that the NSArray has the same shape
- (void)recursivelyCopyNSArray:(NSArray *)array {
    [self recursivelyCopyNSArray:array topLevelSubscript:@[]];
}

- (void)recursivelyCopyNSArray:(NSArray *)array topLevelSubscript:(NSArray *)topSubscript
{
    if (topSubscript.count == self.shape.count - 1) {
        // The last dimension
        NSInteger count = [self.shape.lastObject integerValue];
        NSMutableArray *subscript = [topSubscript mutableCopy];
        [subscript addObject:[NSNumber numberWithInt:0]];
        
        for (NSInteger i = 0; i < count; i++) {
            subscript[subscript.count - 1] = [NSNumber numberWithInteger:i];
            id object = [array objectForKeyedSubscript:subscript];
            [self setObject:object forKeyedSubscript:subscript];
        }
    } else {
        NSInteger subdimensionsCount = [self.shape[topSubscript.count] integerValue];
        for (NSInteger i = 0; i < subdimensionsCount; i++) {
            NSArray *subscript = [topSubscript arrayByAddingObject:
                                  [NSNumber numberWithInteger:i]];
            [self recursivelyCopyNSArray:array topLevelSubscript:subscript];
        }
    }
}

- (NSArray *)NSArray
{
    return [self recursiveDumpWithTopLevelSubscript:@[]];
}

- (NSArray *)recursiveDumpWithTopLevelSubscript:(NSArray *)topSubscript
{
    NSMutableArray *output = [NSMutableArray array];
    
    NSInteger itemsCount = [self.shape[topSubscript.count] integerValue];
    NSMutableArray *subscript = [topSubscript mutableCopy];
    [subscript addObject:[NSNumber numberWithInt:0]];
    
    if (topSubscript.count == self.shape.count - 1) {
        // The last dimension
        for (NSInteger i = 0; i < itemsCount; i++) {
            subscript[subscript.count - 1] = [NSNumber numberWithInteger:i];
            id object = [self objectForKeyedSubscript:subscript];
            [output addObject:object];
        }
    } else {
        for (NSInteger i = 0; i < itemsCount; i++) {
            subscript[subscript.count - 1] = [NSNumber numberWithInteger:i];
            [output addObject:[self recursiveDumpWithTopLevelSubscript:subscript]];
        }
    }
    
    return output;
}

@end
