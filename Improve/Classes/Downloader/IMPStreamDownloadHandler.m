//
//  IMPStreamDownloadHandler.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/31/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <zlib.h>
#import "IMPStreamDownloadHandler.h"
#import "IMPLogging.h"

@interface IMPStreamDownloadHandler()

@end

@implementation IMPStreamDownloadHandler{
    int _bytesReceived;
    IMPModelDownloaderCompletion _completion;
    z_stream _stream;
    NSMutableData *_zipInputData;
    NSMutableData *_zipOutputData;
}

- (void)downloadWithCompletion:(IMPModelDownloaderCompletion)completion{
    _completion = completion;
    _bytesReceived = 0;
    
    // callback in non-main thread
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:queue];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.modelUrl];
    [[session dataTaskWithRequest:request] resume];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error && _completion) {
        [self onDownloadError:@"didCompleteWithError" withErrCode:-500];
    }
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    NSHTTPURLResponse *res = (NSHTTPURLResponse *)response;
    if(res.statusCode == 200){
        // retrieve gzip file contnet length from http response header fields
        NSUInteger contentLength = [[res.allHeaderFields objectForKey:@"Content-Length"] unsignedIntValue];
        _zipInputData = [NSMutableData dataWithCapacity:contentLength];
        _zipOutputData = [NSMutableData dataWithCapacity:contentLength*2];
        _stream.next_in = (Bytef *)_zipInputData.bytes;
        _stream.avail_in = 0;
        
        if(inflateInit2(&_stream, 47)){ // why 47?
            [self onDownloadError:@"" withErrCode:-400];
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
    _bytesReceived += data.length;
    
    NSLog(@"didReceiveData, %ld, avail_in=%u, bytesReceived=%d, %p", data.length, _stream.avail_in, _bytesReceived, _zipInputData.bytes);
    
    int status = Z_OK;
    do {
        if(_stream.total_out >= _zipOutputData.length){
            _zipOutputData.length += 500 * 1024;
        }
        _stream.next_out = (uint8_t *)_zipOutputData.mutableBytes + _stream.total_out;
        _stream.avail_out = (uInt)(_zipOutputData.length - _stream.total_out);
        status = inflate(&_stream, Z_SYNC_FLUSH);
    } while(status == Z_OK && _stream.total_out >= _zipOutputData.length);
    
    NSLog(@"didReceiveData, inflate status=%d, outputLength=%ld", status, _zipOutputData.length);
    if(status != Z_OK){
        if(inflateEnd(&_stream) == Z_OK){
            if(status == Z_STREAM_END){
                IMPLog("streaming decompression sucessfully");
                _zipOutputData.length = _stream.total_out;
                [self.delegate onFinishStreamDownload:_zipOutputData withCompletion:_completion];
            } else {
                [self onDownloadError:@"inflateEnd err" withErrCode:-100];
            }
        } else {
            [self onDownloadError:@"inflateEnd err" withErrCode:-200];
        }
    } else {
        // gzip expecting more data, do nothing here
    }
}

- (void)onDownloadError:(NSString *)msg withErrCode:(int)code{
    NSError *error = [NSError errorWithDomain:@"ai.improve.IMPModelDownloader"
                                         code:code
                                     userInfo:@{NSLocalizedDescriptionKey:msg}];
    if(_completion != nil){
        _completion(nil, error);
        _completion = nil;
    }
    _delegate = nil;
}

@end
