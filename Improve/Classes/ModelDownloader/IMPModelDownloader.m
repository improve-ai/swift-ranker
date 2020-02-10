//
//  IMPModelDownloader.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelDownloader.h"
#import <CoreML/CoreML.h>

@implementation IMPModelDownloader {
    NSURLSessionDataTask *_downloadTask;
}

- (instancetype)initWithURL:(NSURL *)remoteURL
{
    self = [super init];
    if (self) {
        _remoteURL = remoteURL;
    }
    return self;
}

- (void)loadWithCompletion:(IMPModelDownloaderCompletion)completion
{
    NSURLSession *session = [NSURLSession sharedSession];
    _downloadTask = [session dataTaskWithURL:self.remoteURL
                           completionHandler:
                     ^(NSData * _Nullable data,
                       NSURLResponse * _Nullable response,
                       NSError * _Nullable error) {
        if (!data) {
            if (completion) { completion(nil, error); }
            return;
        }

        NSURL *tempDir = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        NSURL *modelDefinitionURL = [tempDir URLByAppendingPathComponent:self.modelFilename];
        [data writeToURL:modelDefinitionURL atomically:YES];

        NSError *savingError = nil;
        NSURL *localURL = [self compileModelAtURL:modelDefinitionURL error:&savingError];
        if (completion) { completion(localURL, savingError); }
    }];
    [_downloadTask resume];
}

- (void)cancel
{
    [_downloadTask cancel];
}

- (NSString *)modelFilename { return self.remoteURL.lastPathComponent; }

- (NSURL *)compileModelAtURL:(NSURL *)modelDefinitionURL error:(NSError **)error
{
    NSURL *compiledURL = [MLModel compileModelAtURL:modelDefinitionURL error:error];
    if (!compiledURL) return nil;

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportDirectory = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:compiledURL create:YES error:error];
    NSURL *permanentURL = [appSupportDirectory URLByAppendingPathComponent:compiledURL.lastPathComponent];
    if ([fileManager fileExistsAtPath:permanentURL.path]) {
        if (![fileManager replaceItemAtURL:permanentURL withItemAtURL:compiledURL backupItemName:nil options:0 resultingItemURL:nil error:error]) {
            return nil;
        }
    } else {
        if (![fileManager copyItemAtURL:compiledURL toURL:permanentURL error:error]) {
            return nil;
        }
    }
    return permanentURL;
}

@end
