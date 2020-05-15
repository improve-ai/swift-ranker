//
//  IMPModelDownloader.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelDownloader.h"
#import <CoreML/CoreML.h>
#import "IMPCommon.h"
#import "NSFileManager+SafeCopy.h"

// https://github.com/nvh/NVHTarGzip
// We can add pod dependency if the author will fix bug with `gzFile` pointers.
// See issue: https://github.com/nvh/NVHTarGzip/pull/24
#import "NVHTarGzip.h"

/**
 The folder in Application Support directory. Contains models, for each model name there is two files:
 - modelname.mlmodelc
 - modelname.json
 */
NSString *const kModelsFolderName = @"Models";


@implementation IMPModelDownloader {
    NSURLSessionDataTask *_downloadTask;

    NSFileManager *_fileManager;
}

+ (NSURL *)modelsDirURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSURL *appSupportDir = [fileManager URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (!appSupportDir) {
        NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);
    }
    NSURL *url = [appSupportDir URLByAppendingPathComponent:kModelsFolderName];

    // Ensure existance
    if (![url checkResourceIsReachableAndReturnError:nil]) {
        if(![fileManager createDirectoryAtURL:url
                  withIntermediateDirectories:true
                                   attributes:nil
                                        error:nil]) {
            NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);
        }
    }

    return url;
}

+ (NSDictionary *)cachedModelBundlesByName
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:self.modelsDirURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (!fileURLs) {
        NSLog(@"-[%@ %@]: %@", CLASS_S, CMD_S, error);
        return nil;
    }

    NSMutableDictionary *bundlesByName = [NSMutableDictionary new];
    for (NSURL *url in fileURLs)
    {
        NSString *extension = url.pathExtension;
        NSString *name = url.lastPathComponent.stringByDeletingPathExtension;

        if (![extension isEqualToString:@"json"]) {
            continue;
        }

        IMPModelBundle *bundle = [[IMPModelBundle alloc] initWithDirectoryURL:self.modelsDirURL modelName:name];

        // Check if all files for the givent model name exists
        if (bundle.isReachable) {
            bundlesByName[name] = bundle;
        }
    }

    return bundlesByName;
}

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL
{
    self = [super init];
    if (self) {
        _remoteArchiveURL = [remoteArchiveURL copy];
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

        // Perform additional check to exit early and prevent further errors.
        NSError *error; // General purpose error
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSInteger statusCode = httpResponse.statusCode;
        if (statusCode != 200)
        {
            NSString *statusCodeStr = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
            NSString *msg = [NSString stringWithFormat:@"Model loading failed with status code: %ld %@.", statusCode, statusCodeStr];
            error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                        code:-1
                                    userInfo:@{NSLocalizedDescriptionKey: msg}];
            if (completion) { completion(nil, error); }
            return;
        }

        // Save downloaded archive
        NSString *tempDir = NSTemporaryDirectory();
        NSString *archivePath = [tempDir stringByAppendingPathExtension:@"models.tar.gz"];
        if (![data writeToFile:archivePath atomically:YES]) {
            NSString *errMsg = @"Failed to write received data to file.";
            error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                        code:-100
                                    userInfo:@{NSLocalizedDescriptionKey: errMsg}];
            if (completion) { completion(nil, error); }
            return;
        }

        // Unarchiving
        NSString *unarchivePath = [tempDir stringByAppendingPathComponent:@"Unarchived Models"];
        if (![[NVHTarGzip sharedInstance] unTarGzipFileAtPath:archivePath
                                                       toPath:unarchivePath
                                                        error:&error])
        {
            if (completion) { completion(nil, error); }
            return;
        }

        NSDictionary *bundlesByName = [self processUnarchivedModelFilesIn:unarchivePath];
        if (completion) { completion(bundlesByName, nil); }
    }];
    [_downloadTask resume];
}

- (void)cancel
{
    [_downloadTask cancel];
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

    if (![_fileManager safeCopyItemAtURL:compiledURL toURL:destURL error:error]) {
        return false;
    }
    return true;
}

- (BOOL)isLoading {
    return _downloadTask && _downloadTask.state != NSURLSessionTaskStateRunning;
}

/// @returns Dictionary { "model name": IMPModelBundle }
- (NSDictionary *)processUnarchivedModelFilesIn:(NSString *)folder
{
    NSURL *folderURL = [NSURL fileURLWithPath:folder];
    NSError *error;

    NSArray *files = [_fileManager contentsOfDirectoryAtURL:folderURL
                                 includingPropertiesForKeys:nil
                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                                      error:&error];

    // Filter files
    NSMutableSet *mlmodelNames = [NSMutableSet setWithCapacity:files.count];
    NSMutableSet *jsonNames = [NSMutableSet setWithCapacity:files.count];
    for (NSURL *file in files)
    {
        NSString *extension = file.pathExtension;
        NSString *modelName = file.lastPathComponent.stringByDeletingPathExtension;

        if ([extension isEqualToString:@"mlmodel"]) {
            [mlmodelNames addObject:modelName];
        } else if ([extension isEqualToString:@"json"]) {
            [jsonNames addObject:modelName];
        }
    }
    [mlmodelNames intersectSet:jsonNames];

    // Process models
    NSMutableDictionary *modelBundlesByName = [NSMutableDictionary new];
    for (NSString *modelName in mlmodelNames)
    {
        NSString *mlmodelFileName = [NSString stringWithFormat:@"%@.mlmodel", modelName];
        NSString *mlmodelPath = [folder stringByAppendingPathComponent:mlmodelFileName];

        NSString *jsonFileName = [NSString stringWithFormat:@"%@.json", modelName];
        NSString *jsonPath = [folder stringByAppendingPathComponent:jsonFileName];

        IMPModelBundle *bundleOrNil = [self processModelWithName:modelName
                                                        withPath:mlmodelPath
                                                        jsonPath:jsonPath];
        modelBundlesByName[modelName] = bundleOrNil;
    }

    return modelBundlesByName;
}

- (IMPModelBundle *)processModelWithName:(NSString *)modelName
                                withPath:(NSString *)mlmodelPath
                                jsonPath:(NSString *)jsonPath
{
    IMPModelBundle *bundle = [[IMPModelBundle alloc] initWithDirectoryURL:self.class.modelsDirURL modelName:modelName];

    // Compile model and put to the destination folder
    NSURL *modelDefinitionURL = [NSURL fileURLWithPath:mlmodelPath];
    NSError *error;
    if (![self compileModelAtURL:modelDefinitionURL
                           toURL:bundle.compiledModelURL
                           error:&error])
    {
        return nil;
    }

    // Put metadata to the destination folder
    NSURL *metadataURL = [NSURL fileURLWithPath:jsonPath];
    if (![_fileManager safeCopyItemAtURL:metadataURL
                                   toURL:bundle.metadataURL
                                   error:&error])
    {
        return nil;
    }

    return bundle;
}

@end
