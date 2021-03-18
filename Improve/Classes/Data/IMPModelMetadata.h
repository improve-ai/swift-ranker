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

@property (readonly, nonatomic) NSString *modelName;

@property (assign, nonatomic) uint32_t seed;

- (instancetype)initWithDict:(NSDictionary *)json;

- (nullable instancetype)initWithString:(NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
