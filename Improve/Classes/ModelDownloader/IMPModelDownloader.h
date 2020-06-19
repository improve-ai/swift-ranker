//
//  IMPModelDownloader.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelBundle.h"


typedef void (^IMPModelDownloaderCompletion) (NSArray *_Nullable modelBundles, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

/**
 Downloads models, compiles them to obtain .mlmodelc file and stores model files in cache.
 */
@interface IMPModelDownloader : NSObject

@property(strong, nonatomic) NSURL *remoteArchiveURL;

@property(strong, nonatomic) NSDictionary *headers;

@property(readonly, nonatomic) BOOL isLoading;

@property(readonly, nonatomic, nullable) NSArray *cachedModelBundles;

/**
 Returns age of the cached models if any. Returns DBL_MAX if models are missing.
 */
@property(readonly, nonatomic) NSTimeInterval cachedModelsAge;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL NS_DESIGNATED_INITIALIZER;

- (void)loadWithCompletion:(nullable IMPModelDownloaderCompletion)completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
