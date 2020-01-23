//
//  NSArray+Padding.h
//  FeatureHasher
//
//  Created by Vladimir on 1/18/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableArray (Padding)

- (instancetype)initWithPadding:(id)padding count:(NSUInteger)count;

@end

@interface NSArray (Padding)

- (instancetype)initWithPadding:(id)padding count:(NSUInteger)count;

@end

NS_ASSUME_NONNULL_END
