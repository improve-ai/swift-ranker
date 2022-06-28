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
    NSFileHandle *_uncompressedFileHandle;
    NSURL *_uncompressedFileURL;
    BOOL _uncompressOK;
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
    
    if(![self createUncompressedFileForWriting]) {
        [self onDownloadError:@"Failed to create temp file for writing"
                  withErrCode:-301];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    
    int ret = inflateInit2(&_stream, 47);
    if(ret) {
        [self onDownloadError:[NSString stringWithFormat:@"inflateInit2 returns %d", ret]
                  withErrCode:-302];
        completionHandler(NSURLSessionResponseCancel);
        return ;
    }
    
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
            [zipOutputData increaseLengthBy:data.length*2];
        }
        _stream.next_out = (uint8_t *)zipOutputData.mutableBytes + (_stream.total_out - total_out);
        _stream.avail_out = (uInt)(zipOutputData.length - (_stream.total_out - total_out));
        status = inflate(&_stream, Z_SYNC_FLUSH);
    } while(status == Z_OK && (_stream.total_out - total_out) >= zipOutputData.length);
    //IMPLog("status=%d, total_out=%lu, data.length= %ld, length=%ld", status, _stream.total_out, data.length, zipOutputData.length);
    
    // Note that Z_BUF_ERROR is not fatal, and inflate() can be called again with more input and
    // more output space to continue decompressing.
    if(status == Z_OK || status == Z_STREAM_END || status == Z_BUF_ERROR) {
        zipOutputData.length = _stream.total_out - total_out;
        @try {
            [_uncompressedFileHandle writeData:zipOutputData];
            if(status == Z_STREAM_END) {
                _uncompressOK = YES;
                [_uncompressedFileHandle closeFile];
            }
        } @catch(NSException *e) {
            IMPErrLog("writeData exception: %@", e);
            [_uncompressedFileHandle closeFile];
            _uncompressedFileHandle = nil;
        }
    }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        inflateEnd(&_stream);
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
    
    if(!_uncompressOK) {
        [self onDownloadError:@"inconsistent stream state"
                  withErrCode:-202];
        return ;
    }
    
    [self compileModelwithCompletion:_completion];
}

- (BOOL)createUncompressedFileForWriting {
    NSString *tempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"ai.improve.tmp.%@.mlmodel", [[NSUUID UUID] UUIDString]]];
    if(![[NSFileManager defaultManager] createFileAtPath:tempPath contents:nil attributes:nil]) {
        return NO;
    }
    
    _uncompressedFileHandle = [NSFileHandle fileHandleForWritingAtPath:tempPath];
    if(_uncompressedFileHandle == nil) {
        return NO;
    }
    
    _uncompressedFileURL = [NSURL fileURLWithPath:tempPath];
    
    return YES;
}

- (void)compileModelwithCompletion:(IMPModelDownloaderCompletion)completion {
    NSError *error;
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSURL *compiledUrl = [MLModel compileModelAtURL:_uncompressedFileURL error:&error];
    if(error) {
        NSString *errMsg = [NSString stringWithFormat:@"Failed to compile: %@", _uncompressedFileURL];
        error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                    code:-101
                                userInfo:@{NSLocalizedDescriptionKey: errMsg}];
        if (completion) {
            completion(nil, error);
        }
        return ;
    }
    
    
    IMPLog("model: %@ compile time: %f ms", self.modelUrl.lastPathComponent, (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0);
    
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

@end
