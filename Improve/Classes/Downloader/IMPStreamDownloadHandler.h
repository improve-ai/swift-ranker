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

@interface IMPStreamDownloadHandler : NSObject <NSURLSessionDataDelegate>

@property (copy, nonatomic) NSURL *modelUrl;

@property (strong, nonatomic) IMPModelDownloaderCompletion completion;

@end

NS_ASSUME_NONNULL_END
