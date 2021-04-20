//
//  IMPStreamDownloadManager.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 4/20/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelDownloader.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPStreamDownloadManager : NSObject

+ (instancetype)sharedManager;

- (void)download:(NSURL *)url WithCompletion:(IMPModelDownloaderCompletion)completion;

@end

NS_ASSUME_NONNULL_END
