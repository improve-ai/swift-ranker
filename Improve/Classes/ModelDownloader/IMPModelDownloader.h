//
//  IMPModelDownloader.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModelBundle.h"


typedef void (^IMPModelDownloaderCompletion) (IMPModelBundle *_Nullable, NSError *_Nullable);

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelDownloader : NSObject

@property(readonly, nonatomic) NSURL *remoteArchiveURL;

@property(readonly, nonatomic) NSString *modelName;

@property(readonly, nonatomic) BOOL isLoading;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL modelName:(NSString *)modelName
NS_DESIGNATED_INITIALIZER;

- (void)loadWithCompletion:(nullable IMPModelDownloaderCompletion)completion;

- (void)cancel;

- (nullable IMPModelBundle *)cachedBundle;

@end

NS_ASSUME_NONNULL_END
