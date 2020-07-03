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
 The folder in Library/Caches directory. Contains subfolders where individual downloaders store
 the cached files. Each subfolder is associated with the corresponding remoteArchiveURL.
 Subfolders contain compiled models file - .mlmodelc and metadata - .json.

 Library/Caches/RootFolder
 - subfoldr1
 -- modelname1.mlmodelc
 -- modelname1.json
 -- modelname2.mlmodelc
 -- modelname2.json
 - subfoldr2
 -- modelname3.mlmodelc
 -- modelname3.json
 */
NSString *const kModelsRootFolderName = @"ai.improve.models";

@implementation IMPModelDownloader {
    /// User Defaults contain NSString - folder name.
    NSString *_userDefaultsFolderKey;

    /// Key for NSDate object - date when the archive was sucesfully downloaded.
    NSString *_userDefaultsLastDownloadDateKey;

    /**
     Random folder name which is associated with the archive URL and stored in User Defaults.
     Cached models for that URL will be stored in this folder.
     */
    NSString *_folderName;

    NSURLSessionDataTask *_downloadTask;

    NSFileManager *_fileManager;
}

- (instancetype)initWithURL:(NSURL *)remoteArchiveURL
{
    self = [super init];
    if (self) {
        _remoteArchiveURL = [remoteArchiveURL copy];
        _fileManager = [NSFileManager defaultManager];

        _userDefaultsFolderKey = [NSString stringWithFormat:@"ai.improve.modelDirectory.%@", remoteArchiveURL.absoluteString];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _folderName = [defaults stringForKey:_userDefaultsFolderKey];
        if (!_folderName) {
            _folderName = [[NSUUID UUID] UUIDString];
            [defaults setObject:_folderName forKey:_userDefaultsFolderKey];
        }

        _userDefaultsLastDownloadDateKey = [NSString stringWithFormat:@"ai.improve.lastDownloadDate.%@", remoteArchiveURL.absoluteString];
    }
    return self;
}

- (NSURL *)modelsDirURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSURL *cachesDir = [fileManager URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (!cachesDir) {
        NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);
    }
    NSURL *url = [cachesDir URLByAppendingPathComponent:kModelsRootFolderName];
    url = [cachesDir URLByAppendingPathComponent:_folderName];

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

- (NSArray *)cachedModelFileURLs {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *fileURLs = [fileManager contentsOfDirectoryAtURL:self.modelsDirURL includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (!fileURLs) {
        NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);
    }
    return fileURLs;
}

- (nullable NSArray *)cachedModelBundles
{
    NSArray *fileURLs = [self cachedModelFileURLs];
    if (!fileURLs) {
        return nil;
    }

    NSMutableArray *bundles = [NSMutableArray new];
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
            [bundles addObject:bundle];
        }
    }

    return bundles;
}

- (NSTimeInterval)cachedModelsAge {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *fileURLs = [self cachedModelFileURLs];
    if (!fileURLs || fileURLs.count == 0) {
        // No files - no cached models yet or cache was purged
        [defaults removeObjectForKey:_userDefaultsLastDownloadDateKey];
        return DBL_MAX;
    }

    NSDate *lastDownloadDate = [defaults objectForKey:_userDefaultsLastDownloadDateKey];
    if (!lastDownloadDate) {
        return DBL_MAX;
    }

    NSTimeInterval age = -[lastDownloadDate timeIntervalSinceNow];
    return age;
}

- (void)loadWithCompletion:(IMPModelDownloaderCompletion)completion
{
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.remoteArchiveURL];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:self.headers];
    // Disable the built-in cache, because we rely on the custom one.
    request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
    _downloadTask = [session dataTaskWithRequest:request
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

        // Optional check for HTTP responses, will not be called for file URLs

        if ([response isKindOfClass:NSHTTPURLResponse.class])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode != 200) {
                NSString *statusCodeStr = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *msg = [NSString stringWithFormat:@"Model loading failed with status code: %ld %@. Data: %@", statusCode, statusCodeStr, dataStr];
                error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: msg}];
                if (completion) { completion(nil, error); }
                return;
            }
        }

        // Save downloaded archive
        NSString *tempDir = NSTemporaryDirectory();
        NSString *archivePath = [tempDir stringByAppendingPathComponent:@"ai.improve.tmp/models.tar.gz"];
        if (![data writeToFile:archivePath atomically:YES]) {
            NSString *errMsg = [NSString stringWithFormat:@"Failed to write received data to file. Path: %@ Size: %ld", archivePath, data.length];
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

        NSArray *bundles = [self processUnarchivedModelFilesIn:unarchivePath];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date]
                                                  forKey:self->_userDefaultsLastDownloadDateKey];
        if (completion) { completion(bundles, nil); }
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

- (NSArray<IMPModelBundle *> *)processUnarchivedModelFilesIn:(NSString *)folder
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
    NSMutableArray *modelBundles = [NSMutableArray arrayWithCapacity:mlmodelNames.count];
    for (NSString *modelName in mlmodelNames)
    {
        NSString *mlmodelFileName = [NSString stringWithFormat:@"%@.mlmodel", modelName];
        NSString *mlmodelPath = [folder stringByAppendingPathComponent:mlmodelFileName];

        NSString *jsonFileName = [NSString stringWithFormat:@"%@.json", modelName];
        NSString *jsonPath = [folder stringByAppendingPathComponent:jsonFileName];

        IMPModelBundle *bundleOrNil = [self processModelWithName:modelName
                                                        withPath:mlmodelPath
                                                        jsonPath:jsonPath];
        [modelBundles addObject:bundleOrNil];
    }

    return modelBundles;
}

- (IMPModelBundle *)processModelWithName:(NSString *)modelName
                                withPath:(NSString *)mlmodelPath
                                jsonPath:(NSString *)jsonPath
{
    IMPModelBundle *bundle = [[IMPModelBundle alloc] initWithDirectoryURL:self.modelsDirURL modelName:modelName];

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
