//
//  IMPModelBundle.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelBundle : NSObject

/// URL to compiled .mlmodelc file.
@property(readonly, nonatomic) NSURL *modelURL;

/// URL to metatdata .json.
@property(readonly, nonatomic) NSURL *metadataURL;

- (instancetype)initWithModelURL:(NSURL *)modelURL metadataURL:(NSURL* )metadataURL
NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
