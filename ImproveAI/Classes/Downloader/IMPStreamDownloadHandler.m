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
    NSFileHandle *_fileHandle;
    NSURL *_fileURL;
    BOOL _decompressOK;
    BOOL _inflateInitialized;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    if(res.statusCode != 200) {
        [self onDownloadError:[NSString stringWithFormat:@"HttpStatusCode=%ld", res.statusCode]
                  withErrCode:-300];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    
    IMPLog("streaming decompression init...");
    int ret = inflateInit2(&_stream, 47);
    if(ret) {
        [self onDownloadError:[NSString stringWithFormat:@"inflateInit2 returns %d", ret]
                  withErrCode:-301];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    _inflateInitialized = YES;
    
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];
    
    if(![[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil]) {
        [self onDownloadError:@"Failed to create temp file for writing"
                  withErrCode:-301];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    
    _fileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
    if(_fileHandle == nil) {
        [self onDownloadError:@"Failed to get the FileHandle for writing"
                  withErrCode:-302];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    
    _fileURL = [NSURL fileURLWithPath:tempPath];
    
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    _stream.next_in = (Bytef *)data.bytes;
    _stream.avail_in += data.length;
    
    uLong total_out = _stream.total_out;
    NSMutableData *zipOutputData = [NSMutableData dataWithCapacity:data.length * 2];
    int status = Z_OK;
    do {
        if((_stream.total_out - total_out) >= zipOutputData.length) {
            [zipOutputData increaseLengthBy:50 * 1024];
        }
        _stream.next_out = (uint8_t *)zipOutputData.mutableBytes + (_stream.total_out - total_out);
        _stream.avail_out = (uInt)(zipOutputData.length - (_stream.total_out - total_out));
        status = inflate(&_stream, Z_SYNC_FLUSH);
    } while(status == Z_OK && (_stream.total_out - total_out) >= zipOutputData.length);
    IMPLog("status=%d, total_out=%lu, data.length= %ld, length=%ld", status, _stream.total_out, data.length, zipOutputData.length);
    
    if(status == Z_OK || status == Z_STREAM_END) {
        zipOutputData.length = _stream.total_out - total_out;
        @try {
            [_fileHandle writeData:zipOutputData];
        } @catch(NSException *e) {
            IMPErrLog("writeData exception: %@", e);
            [_fileHandle closeFile];
            _fileHandle = nil;
        }
    }
    
    if (status == Z_STREAM_END) {
        IMPLog("Reach to stream end");
        _decompressOK = YES;
        [_fileHandle closeFile];
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        if(_inflateInitialized) {
            inflateEnd(&_stream);
        }
        if(_completion) {
            _completion(nil, error);
            _completion = nil;
        }
        return ;
    }
    
    int ret = inflateEnd(&_stream);
    if(ret != Z_OK) {
        [self onDownloadError:[NSString stringWithFormat:@"inflateEnd returns %d", ret]
                  withErrCode:-201];
        return ;
    }
    
    IMPLog("streaming decompression finished, length = %lu", _stream.total_out);
    if(!_decompressOK) {
        [self onDownloadError:@"inconsistent stream state"
                  withErrCode:-202];
        return ;
    }
    
    IMPLog("start compiling CoreML model...");
    [self compileModelwithCompletion:_completion];
}

- (void)compileModelwithCompletion:(IMPModelDownloaderCompletion)completion {
    NSError *error;
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSURL *compiledUrl = [MLModel compileModelAtURL:_fileURL error:&error];
    if(error) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to compile: %@", _fileURL];
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
