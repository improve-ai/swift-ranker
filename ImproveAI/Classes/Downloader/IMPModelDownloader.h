//
//  IMPModelDownloader.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

typedef void (^IMPModelDownloaderCompletion) (MLModel *_Nullable model, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

/**
 Downloads models, compiles them to obtain .mlmodelc file and stores model files in cache.
 */
@interface IMPModelDownloader : NSObject<NSURLSessionDataDelegate>

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL NS_DESIGNATED_INITIALIZER;

- (void)downloadWithCompletion:(nullable IMPModelDownloaderCompletion)completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
