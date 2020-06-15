//
//  NSArray+Random.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (Random)

- (nullable id)randomObject;

- (nonnull NSArray *)shuffledArray;

@end
