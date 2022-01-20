//
//  DownloaderTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/10/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPModelDownloader.h"
#import "TestUtils.h"

extern NSString * const kRemoteModelURL;

@interface DownloaderTest : XCTestCase

@end

// Disclose private methods for test
@interface IMPModelDownloader ()

- (BOOL)compileModelAtURL:(NSURL *)modelDefinitionURL
                    toURL:(NSURL *)destURL
                    error:(NSError **)error;

- (NSURL *)cachedModelURL;

- (NSTimeInterval)cachedModelAge;

@end

@implementation DownloaderTest

- (void)testDownloadLocal{
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"TestModel"
                         withExtension:@"dat"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:modelURL];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testDownloadLocalGzip{
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"TestModel.mlmodel"
                         withExtension:@"gz"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:modelURL];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];

}

- (void)testDownloadRemote{
    NSURL *url = [NSURL URLWithString:kRemoteModelURL];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testDownloadRemoteGzip{
    NSURL *url = [NSURL URLWithString:kRemoteModelURL];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:600.0];
}

- (void)testDownloadCompiled{
    NSURL *url = [[TestUtils bundle] URLForResource:@"TestModel"
                                           withExtension:@"mlmodelc"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:3.0];
}

- (void)testBatchStreamingDownload {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    [[NSURLCache sharedURLCache] setDiskCapacity:300 * 1024 * 1024];
    [[NSURLCache sharedURLCache] setMemoryCapacity:300 * 1024 * 1024];
    
    NSLog(@"cache capacity: %lu, %lu", [[NSURLCache sharedURLCache] diskCapacity],
          [[NSURLCache sharedURLCache] memoryCapacity]);
    
    int loop = 1;
    __block int done = 0;
    double sleepInterval = 1.0f;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    for (int i = 0; i < loop; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 6 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSURL *url = [NSURL URLWithString:@"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/improveai-songs-2.0.mlmodel.gz"];
            IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
            [downloader downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable error) {
                if (error != nil) {
                    XCTFail(@"Downloading error: %@", error);
                }
                XCTAssert(compiledModelURL != nil);
                done++;
                
                if(done == loop){
                    [expectation fulfill];
                }
                
                NSLog(@"%d done, Compiled model URL: %@", done, compiledModelURL);
            }];
        });
        [NSThread sleepForTimeInterval:sleepInterval];
    }
    [self waitForExpectations:@[expectation] timeout:300.0];
}

@end
