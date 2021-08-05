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
    NSURL *url = [NSURL fileURLWithPath:@"/Users/phx/workspace/improve-ai/Improve/Tests/ImproveUnitTests/TestModel.mlmodel"];
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

- (void)testDownloadLocalGzip{
    NSURL *url = [NSURL fileURLWithPath:@"/Users/phx/workspace/improve-ai/Improve/Tests/ImproveUnitTests/TestModel.mlmodel.gz"];
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

- (void)testDownloadRemote{
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.101:14000/static/improve-ai/TestModel.mlmodel"];
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
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.101:14000/static/improve-ai/TestModel.mlmodel3.gz"];
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
//    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    [[NSURLCache sharedURLCache] setDiskCapacity:300 * 1024 * 1024];
    [[NSURLCache sharedURLCache] setMemoryCapacity:300 * 1024 * 1024];
    NSLog(@"cache capacity: %lu, %lu", [[NSURLCache sharedURLCache] diskCapacity],
          [[NSURLCache sharedURLCache] memoryCapacity]);
    
    int loop = 1;
    __block int done = 0;
    double sleepInterval = 1.0f;
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    for (int i = 0; i < loop; i++) {
        NSURL *url = [NSURL URLWithString:@"http://192.168.1.101/TestModel.mlmodel3.gz"];
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
        [NSThread sleepForTimeInterval:sleepInterval];
    }
    [self waitForExpectations:@[expectation] timeout:300.0];
}

@end
