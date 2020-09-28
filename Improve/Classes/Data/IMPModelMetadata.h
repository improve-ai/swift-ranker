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

@property (readonly, nonatomic) NSString *model;
@property (assign, nonatomic) NSUInteger numberOfFeatures;

/// Feature encoding lookup table. May be several MB big.
@property (readonly, nonatomic) NSArray *lookupTable;

@property (assign, nonatomic) uint32_t seed;

- (nullable instancetype)initWithDict:(NSDictionary *)json;

@end

NS_ASSUME_NONNULL_END
