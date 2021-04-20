//
//  IMPStreamDownloadManager.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 4/20/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPStreamDownloadManager.h"
#import "IMPStreamDownloadHandler.h"

@interface IMPStreamDownloadManager() <NSURLSessionDataDelegate>

@property (strong, nonatomic) NSURLSession *urlSession;

@property (strong, nonatomic) NSMutableDictionary *streamDownloadHandlerDict;

@end

@implementation IMPStreamDownloadManager

+ (instancetype)sharedManager {
    static IMPStreamDownloadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (NSMutableDictionary *)streamDownloadHandlerDict {
    if(_streamDownloadHandlerDict == nil){
        _streamDownloadHandlerDict = [[NSMutableDictionary alloc] init];
    }
    return _streamDownloadHandlerDict;
}

- (NSURLSession *)urlSession {
    if(_urlSession == nil){
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _urlSession = [NSURLSession sessionWithConfiguration:sessionConfig
                                                    delegate:self
                                               delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _urlSession;
}

- (void)download:(NSURL *)url WithCompletion:(IMPModelDownloaderCompletion)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request addValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    NSURLSessionDataTask *dataTask = [self.urlSession dataTaskWithRequest:request];
    NSString *taskIdentifier = [@(dataTask.taskIdentifier) stringValue];
    
    IMPStreamDownloadHandler *handler = [[IMPStreamDownloadHandler alloc] init];
    handler.modelUrl = url;
    handler.completion = completion;
    self.streamDownloadHandlerDict[taskIdentifier] = handler;
    
    [dataTask resume];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
                                 didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    NSString *taskIdentifier = [@(dataTask.taskIdentifier) stringValue];
    IMPStreamDownloadHandler *handler = self.streamDownloadHandlerDict[taskIdentifier];
    [handler URLSession:session dataTask:dataTask didReceiveResponse:response completionHandler:completionHandler];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    NSString *taskIdentifier = [@(dataTask.taskIdentifier) stringValue];
    IMPStreamDownloadHandler *handler = self.streamDownloadHandlerDict[taskIdentifier];
    [handler URLSession:session dataTask:dataTask didReceiveData:data];
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSString *taskIdentifier = [@(task.taskIdentifier) stringValue];
    IMPStreamDownloadHandler *handler = self.streamDownloadHandlerDict[taskIdentifier];
    [handler URLSession:session task:task didCompleteWithError:error];
    
    [self.streamDownloadHandlerDict removeObjectForKey:taskIdentifier];
}

@end
