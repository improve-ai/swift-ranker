//
//  NSArray+Random.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "NSArray+Random.h"

@implementation NSArray (Random)

- (nullable id)randomObject
{
    if (self.count == 0) { return nil; }

    NSUInteger randomIdx = arc4random_uniform((uint32_t)self.count);
    return self[randomIdx];
}

@end
