//
//  IMPModelDownloader.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelDownloader.h"
#import <CoreML/CoreML.h>

// https://github.com/nvh/NVHTarGzip
// We can add pod dependency if the author will fix bug with `gzFile` pointers.
// See issue:
#import "NVHTarGzip.h"

/**
 The folder in Application Support directory. Contains model bundles, grouped in folders like this:
 - modelname
 -- modelname.mlmodelc
 -- modelname.json
 */
NSString *const kModelsFolderName = @"Models";


@implementation IMPModelDownloader {
    NSURLSessionDataTask *_downloadTask;

    NSFileManager *_fileManager;
}

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL modelName:(NSString *)modelName
{
    self = [super init];
    if (self) {
        _remoteArchiveURL = [remoteArchiveURL copy];
        _modelName = [modelName copy];

        _fileManager = [NSFileManager defaultManager];
    }
    return self;
}

- (void)loadWithCompletion:(IMPModelDownloaderCompletion)completion
{
    NSURLSession *session = [NSURLSession sharedSession];
    _downloadTask = [session dataTaskWithURL:self.remoteArchiveURL
                           completionHandler:
                     ^(NSData * _Nullable data,
                       NSURLResponse * _Nullable response,
                       NSError * _Nullable downloadingError) {
        if (!data) {
            if (completion) { completion(nil, downloadingError); }
            return;
        }

        NSError *error; // General purpose error
        NSFileManager *fileManager = self->_fileManager;

        NSString *tempDir = NSTemporaryDirectory();
        NSString *unarchivePath = [tempDir stringByAppendingPathComponent:self.modelName];
        NSString *archivePath = [unarchivePath stringByAppendingPathExtension:@"tar.gz"];
        if (![data writeToFile:archivePath atomically:YES]) {
            NSString *errMsg = @"Failed to write received data to file.";
            error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                        code:-100
                                    userInfo:@{NSLocalizedDescriptionKey: errMsg}];
            if (completion) { completion(nil, error); }
            return;
        }
        if (![[NVHTarGzip sharedInstance] unTarGzipFileAtPath:archivePath
                                                       toPath:unarchivePath
                                                        error:&error])
        {
            if (completion) { completion(nil, error); }
            return;
        }

        // Ensure dir exists and empty
        NSURL *modelDirURL = [[self modelsDirURL] URLByAppendingPathComponent:self.modelName];
        [fileManager removeItemAtURL:modelDirURL error:nil];
        [fileManager createDirectoryAtURL:modelDirURL
              withIntermediateDirectories:YES
                               attributes:nil
                                    error:NULL];

        // Put model to the destination folder
        NSURL *modelDefinitionURL = [NSURL fileURLWithPath:unarchivePath];
        modelDefinitionURL = [modelDefinitionURL URLByAppendingPathComponent:self.modelName];
        modelDefinitionURL = [modelDefinitionURL URLByAppendingPathExtension:@"mlmodel"];

        NSURL *compiledModelURL = [modelDirURL URLByAppendingPathComponent:self.modelName];
        compiledModelURL = [compiledModelURL URLByAppendingPathExtension:@"mlmodelc"];

        if (![self compileModelAtURL:modelDefinitionURL
                               toURL:compiledModelURL
                               error:&error])
        {
            if (completion) { completion(nil, error); }
            return;
        }

        // Put metadata to the destination folder
        NSString *metadataExtension = @"json";
        NSURL *metadataOrigin = [NSURL fileURLWithPath:unarchivePath];
        metadataOrigin = [metadataOrigin URLByAppendingPathComponent:self.modelName];
        metadataOrigin = [metadataOrigin URLByAppendingPathExtension:metadataExtension];
        NSURL *metadataTarget = [modelDirURL URLByAppendingPathComponent:self.modelName];
        metadataTarget = [metadataTarget URLByAppendingPathExtension:metadataExtension];

        if (![fileManager copyItemAtURL:metadataOrigin
                                  toURL:metadataTarget
                                  error:&error])
        {
            if (completion) { completion(nil, error); }
            return;
        }

        IMPModelBundle *bundle = [[IMPModelBundle alloc] initWithModelURL:compiledModelURL
                                                              metadataURL:metadataTarget];
        if (completion) { completion(bundle, nil); }
    }];
    [_downloadTask resume];
}

- (void)cancel
{
    [_downloadTask cancel];
}

- (NSURL *)modelsDirURL
{
    NSError *error;
    NSURL *appSupportDir = [_fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (!appSupportDir) {
        NSLog(@"-[%@ %@]: %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), error);
    }
    NSURL *url = [appSupportDir URLByAppendingPathComponent:kModelsFolderName];
    return url;
}

- (BOOL)compileModelAtURL:(NSURL *)modelDefinitionURL
                    toURL:(NSURL *)destURL
                    error:(NSError **)error
{
    if (![_fileManager fileExistsAtPath:modelDefinitionURL.path]) {
        NSString *msg = [NSString stringWithFormat:@"Model definition not found %@", modelDefinitionURL.path];
        *error = [NSError errorWithDomain:@"ai.improve.compile_model"
                                     code:1
                                 userInfo:@{NSLocalizedDescriptionKey: msg}];
        return false;
    }

    NSURL *compiledURL = [MLModel compileModelAtURL:modelDefinitionURL error:error];
    if (!compiledURL) return false;

    if ([_fileManager fileExistsAtPath:destURL.path]) {
        if (![_fileManager replaceItemAtURL:destURL withItemAtURL:compiledURL backupItemName:nil options:0 resultingItemURL:nil error:error]) {
            return false;
        }
    } else {
        if (![_fileManager copyItemAtURL:compiledURL toURL:destURL error:error]) {
            return false;
        }
    }
    return true;
}

- (BOOL)isLoading {
    return _downloadTask && _downloadTask.state != NSURLSessionTaskStateRunning;
}

@end
