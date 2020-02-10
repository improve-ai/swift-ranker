//
//  IMPModelDownloader.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^IMPModelDownloaderCompletion) (NSURL *_Nullable localURL, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelDownloader : NSObject

@property(readonly, nonatomic) NSURL *remoteURL;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)remoteURL NS_DESIGNATED_INITIALIZER;

- (void)loadWithCompletion:(nullable IMPModelDownloaderCompletion)completion;

- (void)cancel;

@end

NS_ASSUME_NONNULL_END
