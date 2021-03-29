//
//  IMPModelDownloader.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/8/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//
#import <zlib.h>

#import "IMPModelDownloader.h"
#import <CoreML/CoreML.h>
#import "NSFileManager+SafeCopy.h"
#import "IMPLogging.h"
#import "XXHashUtils.h"


@implementation IMPModelDownloader {
    NSURLSessionDataTask *_downloadTask;
    z_stream _stream;
    NSMutableData *_zipInputBuffer;
    NSMutableData *_zipOutputBuffer;
    IMPModelDownloaderCompletion _completion;
}

- (instancetype)initWithURL:(NSURL *)remoteModelURL maxAge:(NSInteger) maxAge
{
    self = [super init];
    if (self) {
        _remoteModelURL = [remoteModelURL copy];
        _maxAge = maxAge;
        if (_maxAge < 0) {
            _maxAge = 604800;
        }
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)remoteModelURL
{
    return [self initWithURL:remoteModelURL maxAge:-1];
}

- (NSURL *) cachedModelURL
{
    NSError *error;
    NSURL *cachesDir = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if (!cachesDir) {
        return nil;
    }
    NSString *fileName = [self modelFileNameFromURL:self.remoteModelURL];
    return [cachesDir URLByAppendingPathComponent:fileName];
    
}

- (NSString *)modelFileNameFromURL:(NSURL *)remoteURL
{
    NSString *nameFormat = @"ai.improve.cachedmodel.%@.mlmodelc";
    const NSUInteger formatLen = [NSString stringWithFormat:nameFormat, @""].length;

    NSMutableCharacterSet *allowedChars = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowedChars addCharactersInString:@".-_ "];
    NSString *remoteURLStr = [remoteURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
    const NSUInteger urlLen = remoteURLStr.length;

    NSString *fileName;
    // NAME_MAX - max file name
    if (formatLen + urlLen <= NAME_MAX) {
        fileName = [NSString stringWithFormat:nameFormat, remoteURLStr];
    } else {
        const NSUInteger separLen = 2;
        const NSUInteger remainLen = NAME_MAX - formatLen - kXXHashOutputStringLength - separLen;
        const NSUInteger stripLen = urlLen - remainLen;

        NSMutableString *condensedURLStr = [NSMutableString new];
        [condensedURLStr appendString:[remoteURLStr substringToIndex:(remainLen / 2)]];
        [condensedURLStr appendString:@"-"];

        NSRange stripRange = NSMakeRange(remainLen / 2, stripLen);
        NSString *strip = [remoteURLStr substringWithRange:stripRange];
        NSString *encodedStrip = [XXHashUtils encode:strip];
        [condensedURLStr appendString:encodedStrip];
        [condensedURLStr appendString:@"-"];

        NSString *lastPart = [remoteURLStr substringFromIndex:urlLen - (remainLen + 1) / 2];
        [condensedURLStr appendString:lastPart];

        fileName = [NSString stringWithFormat:nameFormat, condensedURLStr];
    }

    return fileName;
}

- (BOOL) isValidCachedModelURL:(NSURL *) url
{
    if (!url) {
        return FALSE;
    }
    // check existence
    if (![url checkResourceIsReachableAndReturnError:nil]) {
        return FALSE;
    }
    
    if (self.cachedModelAge > self.maxAge) {
        return FALSE;
    }
    
    return TRUE;
}

- (NSTimeInterval)cachedModelAge {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDate *lastDownloadDate = [defaults objectForKey:self.lastDownloadDateDefaultsKey];
    if (!lastDownloadDate) {
        return DBL_MAX;
    }

    NSTimeInterval age = -[lastDownloadDate timeIntervalSinceNow];
    return age;
}

- (NSString *) lastDownloadDateDefaultsKey
{
    return [NSString stringWithFormat:@"ai.improve.lastDownloadDate.%@", self.remoteModelURL.absoluteString];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)dataTask.response;

    // only do it in the first didReceiveData callback
    if(_zipInputBuffer == nil && dataTask.response != nil){
        // retrieve gzip file size from headers
        NSUInteger contentLength = [[response.allHeaderFields objectForKey:@"Content-Length"] unsignedIntValue];
        _zipInputBuffer = [NSMutableData dataWithCapacity:contentLength];
        _zipOutputBuffer = [NSMutableData dataWithCapacity:contentLength*2];
        _stream.next_in = (Bytef *)_zipInputBuffer.bytes;
        
        if(inflateInit2(&_stream, 47)){ // why 47?
            NSError *error = [[NSError alloc] initWithDomain:@"improve.ai" code:200 userInfo:@{ NSLocalizedFailureReasonErrorKey:@"LocalizedFailureReason"}];
            _completion(nil, error);
            return ;
        }
    }
    [_zipInputBuffer appendData:data];
    _stream.avail_in += data.length;
    
    if(_stream.total_out >= _zipOutputBuffer.length){
        _zipOutputBuffer.length += _zipInputBuffer.length / 2;
    }
    _stream.next_out = (uint8_t *)_zipOutputBuffer.bytes + _stream.total_out;
    _stream.avail_out = (uInt)(_zipOutputBuffer.length - _stream.total_out);
    int status = inflate(&_stream, Z_SYNC_FLUSH);
    if(status != Z_OK){
        if(inflateEnd(&_stream) == Z_OK){
            if(status == Z_STREAM_END){
                _zipOutputBuffer.length = _stream.total_out;
                [self saveAndCompile:_zipOutputBuffer];
            }
        }
    }
}

- (void)downloadStreamWithCompletion:(IMPModelDownloaderCompletion)completion{
    _completion = completion;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue currentQueue]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.remoteModelURL];
    [[session dataTaskWithRequest:request] resume];
}

- (void)saveAndCompile:(NSData *)data{
    NSError *error;
    
    NSURL *cachedModelURL = self.cachedModelURL;
    
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];

    IMPLog("Writing to path: %@ ...", tempPath);
    if (![data writeToFile:tempPath atomically:YES]) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to write received data to file. Src URL: %@, Dest path: %@ Size: %ld", self.remoteModelURL, tempPath, data.length];
        error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                    code:-100
                                userInfo:@{NSLocalizedDescriptionKey: errMsg}];
        IMPLog("Write failed: %@", errMsg);
        if (_completion) { _completion(nil, error); }
        return;
    }

    IMPLog("Compiling model from %@ to %@", tempPath, cachedModelURL);
    if (![self compileModelAtURL:[NSURL fileURLWithPath:tempPath] toURL:cachedModelURL error:&error]) {
        IMPLog("Compile failed");
        if (_completion) { _completion(nil, error); }
        return;
    }

    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:self.lastDownloadDateDefaultsKey];
    
    IMPLog("Model downloaded finished.");
    if (_completion) { _completion(cachedModelURL, nil); }
}

- (void)downloadWithCompletion:(IMPModelDownloaderCompletion)completion
{
    // check to see if there is a cached .mlmodelc
    NSURL *cachedModelURL = self.cachedModelURL;
    if ([self isValidCachedModelURL:cachedModelURL]) {
        IMPLog("returning cached model %@", cachedModelURL);
        if (completion) { completion(cachedModelURL, nil); }
        return;
    }
    
    if([self.remoteModelURL.absoluteString hasSuffix:@".gz"]){
        NSLog(@"has suffix .gz");
        [self downloadStreamWithCompletion:completion];
        return ;
    }
    IMPLog("Loading model at: %@", self.remoteModelURL);

    NSURLSession *session = [NSURLSession sharedSession];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.remoteModelURL];
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
            IMPLog("Finish loading - no data; response: %@, error: %@", response, downloadingError);
            if (completion) { completion(nil, downloadingError); }
            return;
        }

        NSError *error; // General purpose error

        // Optional check for HTTP responses, will not be called for file URLs
        if ([response isKindOfClass:NSHTTPURLResponse.class])
        {
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
                if (completion) { completion(nil, error); }
                return;
            }
        }

        IMPLog("Loaded %ld bytes.", data.length);

        // Save downloaded model definition
        NSString *tempDir = NSTemporaryDirectory();
        NSString *tempPath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];

        IMPLog("Writing to path: %@ ...", tempPath);
        if (![data writeToFile:tempPath atomically:YES]) {
            NSString *errMsg = [NSString stringWithFormat:@"Failed to write received data to file. Src URL: %@, Dest path: %@ Size: %ld", self.remoteModelURL, tempPath, data.length];
            error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                        code:-100
                                    userInfo:@{NSLocalizedDescriptionKey: errMsg}];
            IMPLog("Write failed: %@", errMsg);
            if (completion) { completion(nil, error); }
            return;
        }

        IMPLog("Compiling model from %@ to %@", tempPath, cachedModelURL);
        if (![self compileModelAtURL:[NSURL fileURLWithPath:tempPath] toURL:cachedModelURL error:&error]) {
            IMPLog("Compile failed");
            if (completion) { completion(nil, error); }
            return;
        }

        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:self.lastDownloadDateDefaultsKey];
        
        IMPLog("Model downloaded finished.");
        if (completion) { completion(cachedModelURL, nil); }
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
    if (![[NSFileManager defaultManager] fileExistsAtPath:modelDefinitionURL.path]) {
        NSString *msg = [NSString stringWithFormat:@"Model definition not found at local path: %@. Remove URL: %@", modelDefinitionURL.path, self.remoteModelURL];
        if (error != NULL)
        {
            *error = [NSError errorWithDomain:@"ai.improve.compile_model"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: msg}];
        }
        return false;
    }

    NSURL *compiledURL = [MLModel compileModelAtURL:modelDefinitionURL error:error];
    if (!compiledURL) return false;

    if (![[NSFileManager defaultManager] safeCopyItemAtURL:compiledURL toURL:destURL error:error]) {
        return false;
    }
    return true;
}

- (BOOL)isLoading {
    return _downloadTask && _downloadTask.state != NSURLSessionTaskStateRunning;
}

@end
