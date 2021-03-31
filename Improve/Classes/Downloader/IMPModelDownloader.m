//  IMPModelDownloader.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//
#import "IMPModelDownloader.h"
#import <CoreML/CoreML.h>
#import "IMPLogging.h"
#import "IMPUtils.h"
#import "NSData+GZIP.h"
#import "IMPStreamDownloadHandler.h"

@interface IMPModelDownloader()<IMPStreamDownloadHandlerDelegate>

@property (strong, nonatomic) NSURL *modelUrl;

@property (strong, nonatomic) NSDictionary *headers;

@property (readonly, nonatomic) BOOL isLoading;

@property (strong, nonatomic) IMPStreamDownloadHandler *streamDownloadHandler;

@end


@implementation IMPModelDownloader {
    NSURLSessionDataTask *_downloadTask;
}

- (instancetype)initWithURL:(NSURL *)remoteModelURL {
    if (self = [super init]) {
        _modelUrl = [remoteModelURL copy];
    }
    return self;
}

- (IMPStreamDownloadHandler *)streamDownloadHandler{
    if(_streamDownloadHandler == nil){
        _streamDownloadHandler = [[IMPStreamDownloadHandler alloc] init];
        _streamDownloadHandler.modelUrl = self.modelUrl;
        _streamDownloadHandler.delegate = self;
    }
    return _streamDownloadHandler;
}

- (void)downloadWithCompletion:(IMPModelDownloaderCompletion)completion {
    if([self.modelUrl.absoluteString hasPrefix:@"http"]){
        if([self.modelUrl.path hasSuffix:@".gz"]) {
            [self.streamDownloadHandler downloadWithCompletion:completion];
        } else {
            [self downloadRemoteWithCompletion:completion];
        }
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [self loadLocal:self.modelUrl WithCompletion:completion];
        });
    }
}

#pragma mark NSURLSessionDataDelegate
- (void)onFinishStreamDownload:(NSData *)data withCompletion:(IMPModelDownloaderCompletion)completion{
    [self saveAndCompile:data withCompletion:completion];
    if(_streamDownloadHandler){
        _streamDownloadHandler.delegate = nil;
    }
}

- (void)saveAndCompile:(NSData *)data withCompletion:(IMPModelDownloaderCompletion)completion{
    NSError *error = nil;
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];
    
    IMPLog("Writing to path: %@ ...", tempPath);
    if (![data writeToFile:tempPath atomically:YES]) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to write received data to file. Src URL: %@, Dest path: %@ Size: %ld", self.modelUrl, tempPath, data.length];
        error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                    code:-100
                                userInfo:@{NSLocalizedDescriptionKey: errMsg}];
        IMPLog("Write failed: %@", errMsg);
        if (completion) {
            completion(nil, error);
        }
        return;
    }

    IMPLog("Compiling model %@", tempPath);
    NSURL *compiledUrl = [self compileModelAtURL:[NSURL fileURLWithPath:tempPath] error:&error];
    if(completion){
        completion(compiledUrl, error);
    }
}

- (void)downloadRemoteWithCompletion:(IMPModelDownloaderCompletion)completion{
    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.modelUrl];
    [request setHTTPMethod:@"GET"];
    [request setAllHTTPHeaderFields:self.headers];
    _downloadTask = [session dataTaskWithRequest:request
                           completionHandler:
                     ^(NSData * _Nullable data,
                       NSURLResponse * _Nullable response,
                       NSError * _Nullable downloadingError) {
        if (!data) {
            IMPLog("Finish loading - no data; response: %@, error: %@", response, downloadingError);
            if (completion) {
                completion(nil, downloadingError);
            }
            return;
        }

        NSError *error; // General purpose error

        // Optional check for HTTP responses, will not be called for file URLs
        if ([response isKindOfClass:NSHTTPURLResponse.class]) {
            // Perform additional check to exit early and prevent further errors.
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            NSInteger statusCode = httpResponse.statusCode;
            if (statusCode != 200) {
                NSString *statusCodeStr = [NSHTTPURLResponse localizedStringForStatusCode:statusCode];
                NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *msg = [NSString stringWithFormat:@"Model loading failed with status code: %ld %@. Data: %@. URL: %@", statusCode, statusCodeStr, dataStr, response.URL];
                error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                            code:-1
                                        userInfo:@{NSLocalizedDescriptionKey: msg}];
                IMPLog("Loading failed: %@", error);
                if (completion) {
                    completion(nil, error);
                }
                return;
            }
        }

        IMPLog("Loaded %ld bytes.", data.length);
        [self saveAndCompile:data withCompletion:completion];
    }];
    [_downloadTask resume];

}

- (void)loadLocal:(NSURL *)url WithCompletion:(IMPModelDownloaderCompletion)completion{
    NSError *error = nil;
    NSURL *localModelURL = url;
    
    // unzip
    if([self.modelUrl.path hasSuffix:@".gz"]){
        localModelURL = [self unzipLocalZipModel:self.modelUrl];
        if(localModelURL == nil) {
            NSError *error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                                 code:-100
                                             userInfo:@{NSLocalizedDescriptionKey: @"unzip error"}];
            IMPLog("unzip failed %@", url);
            if(completion){
                completion(nil, error);
            }
            return ;
        }
    }
    
    NSURL *compiledUrl = [self compileModelAtURL:localModelURL error:&error];
    if(completion){
        completion(compiledUrl, error);
    }
}

- (NSURL *)unzipLocalZipModel:(NSURL *)url{
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSData *unzippedData = [data gunzippedData];
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];
    if(![unzippedData writeToFile:tempPath atomically:YES]){
        return nil;
    }
    return [NSURL fileURLWithPath:tempPath];
}

- (NSURL *)compileModelAtURL:(NSURL *)modelDefinitionURL error:(NSError **)error{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSURL *compiledURL = [MLModel compileModelAtURL:modelDefinitionURL error:error];
    IMPLog("compileTime: %f ms", (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
    return compiledURL;
}

- (void)cancel {
    [_downloadTask cancel];
}

- (BOOL)isLoading {
    return _downloadTask && _downloadTask.state != NSURLSessionTaskStateRunning;
}

- (void)dealloc{
    IMPLog("IMPModelDownloader dealloc called...");
}

@end
