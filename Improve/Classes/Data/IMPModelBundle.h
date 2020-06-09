//
//  IMPModelBundle.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelMetadata.h"

NS_ASSUME_NONNULL_BEGIN

// A bunch of asset URLs related to a model.
@interface IMPModelBundle : NSObject

/// URL to compiled .mlmodelc file.
@property(readonly, nonatomic) NSURL *compiledModelURL;

/// URL to metatdata .json.
@property(readonly, nonatomic) NSURL *metadataURL;

/// Metadata file creation date. Used to check age of a cached model.
@property(readonly, nonatomic) NSDate *_Nullable creationDate;

@property(readonly, nonatomic) BOOL isReachable;

/**
 Metadata extracted from JSON file at `metadataURL`. Initialized lazily because actual metadata file may
 be missing at the moment of bundle creation.
 */
@property(readonly, nonatomic) IMPModelMetadata *metadata;

- (instancetype)initWithModelURL:(NSURL *)modelURL metadataURL:(NSURL* )metadataURL
NS_DESIGNATED_INITIALIZER;

/**
 Initializes a bundle by appending modelName.mlmodel and modelName.json to the `dirURL`.
 */
- (instancetype)initWithDirectoryURL:(NSURL *)dirURL modelName:(NSString *)modelName;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
