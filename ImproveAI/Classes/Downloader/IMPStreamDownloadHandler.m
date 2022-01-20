//
//  IMPStreamDownloadHandler.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/31/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <zlib.h>
#import <CoreML/CoreML.h>
#import "IMPStreamDownloadHandler.h"
#import "IMPLogging.h"

@interface IMPStreamDownloadHandler()

@end

@implementation IMPStreamDownloadHandler {
    z_stream _stream;
    BOOL _decompressOK;
    NSMutableData *_zipInputData;
    NSMutableData *_zipOutputData;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    if(res.statusCode == 200) {
        // retrieve gzip file contnet length from http response header fields
        NSUInteger contentLength = [[res.allHeaderFields objectForKey:@"Content-Length"] unsignedIntValue];
        _zipInputData = [NSMutableData dataWithCapacity:contentLength];
        _zipOutputData = [NSMutableData dataWithCapacity:contentLength*2];
        _stream.next_in = (Bytef *)_zipInputData.bytes;
        _stream.avail_in = 0;
        
        if(inflateInit2(&_stream, 47)) { // why 47?
            [self onDownloadError:@"inflateInit2 err" withErrCode:-400];
            return ;
        }
        completionHandler(NSURLSessionResponseAllow);
    } else {
        NSString *msg = [NSString stringWithFormat:@"http statusCode=%ld, expecting 200", res.statusCode];
        [self onDownloadError:msg withErrCode:-300];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [_zipInputData appendData:data];
    _stream.avail_in += data.length;
    
    int status = Z_OK;
    do {
        if(_stream.total_out >= _zipOutputData.length) {
            _zipOutputData.length += 500 * 1024;
        }
        _stream.next_out = (uint8_t *)_zipOutputData.mutableBytes + _stream.total_out;
        _stream.avail_out = (uInt)(_zipOutputData.length - _stream.total_out);
        status = inflate(&_stream, Z_SYNC_FLUSH);
    } while(status == Z_OK && _stream.total_out >= _zipOutputData.length);
    
    if (status == Z_STREAM_END) {
        _decompressOK = YES;
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error && _completion) {
        inflateEnd(&_stream);
        if(_completion) {
            _completion(nil, error);
            _completion = nil;
        }
        return ;
    }
    
    int status = inflateEnd(&_stream);
    if(status == Z_OK) {
        if(_decompressOK) {
            IMPLog("streaming decompression sucessfully");
            _zipOutputData.length = _stream.total_out;
            [self saveAndCompile:_zipOutputData withCompletion:_completion];
        } else {
            [self onDownloadError:@"decompress err" withErrCode:-200];
        }
    } else {
        [self onDownloadError:@"inflateEnd err" withErrCode:-201];
    }
}

- (void)saveAndCompile:(NSData *)data withCompletion:(IMPModelDownloaderCompletion)completion {
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

    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSURL *compiledUrl = [MLModel compileModelAtURL:[NSURL fileURLWithPath:tempPath] error:&error];
    if(error) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to compile: %@", tempPath];
        error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                    code:-101
                                userInfo:@{NSLocalizedDescriptionKey: errMsg}];
        if (completion) {
            completion(nil, error);
        }
        return ;
    }
    IMPLog("Compile time: %f ms", (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
    
    if(completion) {
        completion(compiledUrl, error);
    }
}

- (void)onDownloadError:(NSString *)msg withErrCode:(int)code {
    NSError *error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey:msg}];
    if(_completion) {
        _completion(nil, error);
        _completion = nil;
    }
}

- (void)dealloc {
    IMPLog("IMPStreamDownloadHandler dealloc called...");
}

@end
