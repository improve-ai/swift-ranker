//
//  IMPModelMetadata.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelMetadata : NSObject

@property (assign, nonatomic) NSUInteger numberOfFeatures;

@property (copy, nonatomic) NSString *modelId;

@property (strong, nonatomic) NSArray *lookupTable;

@property (assign, nonatomic) uint32_t seed;

// coming later: hashing tables

+ (nullable instancetype)metadataWithURL:(NSURL *)url;

- (nullable instancetype)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END
