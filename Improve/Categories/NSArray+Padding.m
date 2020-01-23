//
//  NSArray+Padding.m
//  FeatureHasher
//
//  Created by Vladimir on 1/18/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "NSArray+Padding.h"


@implementation NSMutableArray (Padding)

- (instancetype)initWithPadding:(id)padding count:(NSUInteger)count {
  self = [self init];
  if (!self) {
    return self;
  }

  for (NSUInteger i = 0; i < count; i++) {
    [self addObject:[padding copy]];
  }

  return self;
}

@end


@implementation NSArray (Padding)

- (instancetype)initWithPadding:(id)padding count:(NSUInteger)count {
  NSMutableArray *mutableArray = [[NSMutableArray alloc] initWithCapacity:count];
  for (NSUInteger i = 0; i < count; i++) {
    [mutableArray addObject:[padding copy]];
  }

  self = [self initWithArray:mutableArray];
  return self;
}

@end
