//
//  IMPModelDownloader.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelBundle.h"


typedef void (^IMPModelDownloaderCompletion) (NSArray *_Nullable modelBundles, NSError *_Nullable);

NS_ASSUME_NONNULL_BEGIN

/**
 Downloads models, compiles them to obtain .mlmodelc file and stores model files in cache.
 */
@interface IMPModelDownloader : NSObject

@property(readonly, nonatomic) NSURL *remoteArchiveURL;

@property(readonly, nonatomic) BOOL isLoading;

+ (nullable NSArray *)cachedModelBundles;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL NS_DESIGNATED_INITIALIZER;

- (void)loadWithCompletion:(nullable IMPModelDownloaderCompletion)completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
