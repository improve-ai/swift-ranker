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

extern NSString * const kPlainModelURL;

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
    [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(model != nil);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testDownloadLocalGzip{
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"TestModel.mlmodel"
                         withExtension:@"gz"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:modelURL];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(model != nil);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];

}

- (void)testDownloadRemote{
    NSURL *url = [NSURL URLWithString:kPlainModelURL];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(model != nil);

        [expectation fulfill];

    }];
    [self waitForExpectations:@[expectation] timeout:60.0];
}

/**
 * There was a bug in streaming decompression which happens occasionally. It could have been found
 * earlier if we had done a loop test here.
 */
- (void)testDownloadRemoteGzip{
    self.continueAfterFailure = NO;
    int loop = 100;
    for(int i = 0; i < loop; ++i) {
        NSLog(@"<<<<<<<<<   %d   >>>>>>>>>>", i);
        NSURL *url = [NSURL URLWithString:kRemoteModelURL];
        IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
        
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
        [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
            if (error != nil) {
                XCTFail(@"Downloading error: %@", error);
            }
            XCTAssert(model != nil);

            [expectation fulfill];

        }];
        
        [self waitForExpectations:@[expectation] timeout:600.0];
    }
}

- (void)testDownloadCompiled{
    NSURL *url = [[TestUtils bundle] URLForResource:@"TestModel"
                                           withExtension:@"mlmodelc"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];
    
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(model != nil);

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
    
    int loop = 100;
    for (int i = 0; i < loop; i++) {
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
        IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:[NSURL URLWithString:kRemoteModelURL]];
        [downloader downloadWithCompletion:^(MLModel * _Nullable model, NSError * _Nullable error) {
            if (error != nil) {
                XCTFail(@"Downloading error: %@", error);
            }
            XCTAssert(model != nil);
            
            [expectation fulfill];
        }];
        [self waitForExpectations:@[expectation] timeout:300.0];
    }
}

@end
