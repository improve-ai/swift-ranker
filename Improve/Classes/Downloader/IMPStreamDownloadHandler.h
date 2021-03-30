//
//  IMPStreamDownloadHandler.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/31/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@protocol IMPStreamDownloadHandlerDelegate <NSObject>

- (void)onFinishStreamDownload:(NSData *)data withCompletion:(IMPModelDownloaderCompletion)completion;

@end

@interface IMPStreamDownloadHandler : NSObject <NSURLSessionDataDelegate>

@property (copy, nonatomic) NSURL *modelUrl;

@property (strong, nonatomic) IMPModelDownloaderCompletion completion;

// Why strong modifier is used here.
// When weak is used, after the execution of method in "+loadAsync"
//     [[IMPModelDownloader alloc] initWithURL:url] downloadWithCompletion:completion]
// IMPModelDownloader would be released before the completion block is called,
// and also the weak delegate would be set to nil.
//
// So let it be strong here to keep IMPModelDownloader around for a while
// and set the delegate to nil when the download job is done.
//
// Any suggestion here?
//
@property (strong, nonatomic, nullable) id<IMPStreamDownloadHandlerDelegate> delegate;

- (void)downloadWithCompletion:(IMPModelDownloaderCompletion)completion;

@end

NS_ASSUME_NONNULL_END
