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

- (NSString *)modelFileNameFromURL:(NSURL *)remoteURL;

@end

@implementation DownloaderTest

- (void)testCompile {
    // Insert url for local or remote .mlmodel file here
    NSURL *modelDefinitionURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/29May/model.mlmodel"];
    NSURL *compiledURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/29May/model.mlmodelc"];
    XCTAssertNotNil(modelDefinitionURL);

    // Url isn't used here.
    NSURL *dummyURL = [NSURL fileURLWithPath:@""];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:dummyURL];

    for (NSUInteger i = 0; i < 3; i++) // Loop to check overwriting.
    {
        NSError *err;
        if (![downloader compileModelAtURL:modelDefinitionURL
                                     toURL:compiledURL
                                     error:&err])
        {
            NSLog(@"Compilation error: %@", err);
        }
        XCTAssertNotNil(compiledURL);
        NSLog(@"%@", compiledURL);
    }
    if ([[NSFileManager defaultManager] removeItemAtURL:compiledURL error:nil]) {
        NSLog(@"Deleted.");
    }
}

- (void)testDownload {
    // Insert url for local or remote archive here
    //NSURL *remoteURL = [NSURL URLWithString:@"https://d2pq40dxlsc486.cloudfront.net/myproject/model.tar.gz"];
    NSURL *url = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/multimodels/mlmodels/latest.tar.gz"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:url];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader downloadWithCompletion:^(NSURL *compiledModelURL, NSError *error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(compiledModelURL != nil);
        NSLog(@"Compiled model URL: %@", compiledModelURL);

        // Cleenup
//        NSURL *folderURL = bundle.modelURL.URLByDeletingLastPathComponent;
//        if ([[NSFileManager defaultManager] removeItemAtURL:compiledModelURL error:nil]) {
//            NSLog(@"Deleted.");
//        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testCache {
    NSURL *url = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/multimodels/mlmodels/latest.tar.gz"];
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL: url];

    // Clean before tests
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:[downloader cachedModelURL] error:nil];

    XCTAssertFalse([fileManager fileExistsAtPath:[downloader cachedModelURL].path]);

    NSTimeInterval age = [downloader cachedModelAge];
    XCTAssert(age == DBL_MAX);

    XCTestExpectation *expectation = [[XCTestExpectation alloc] init];
    NSTimeInterval cacheAgeSeconds = 10.0;
    [downloader downloadWithCompletion:^(NSURL *modelURL, NSError *error) {
        XCTAssertNotNil(downloader.cachedModelURL);
        XCTAssert([fileManager fileExistsAtPath:downloader.cachedModelURL.path]);

        NSTimeInterval age = downloader.cachedModelAge;
        NSLog(@"After download cachedModelsAge: %f", age);
        XCTAssert(isEqualRough(age, 0.0, 0.1));

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(cacheAgeSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSTimeInterval age = [downloader cachedModelAge];
            NSLog(@"After %fs cachedModelsAge: %f", cacheAgeSeconds, age);
            XCTAssert(isEqualRough(age, cacheAgeSeconds, 0.1));
            [expectation fulfill];
        });
    }];

    [self waitForExpectations:@[expectation] timeout:cacheAgeSeconds + 30.0];
}

- (void)testModelFileNames
{
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:[NSURL URLWithString:@"www.dummyurl.com"]];

    NSArray *strings = @[
        @"https://my-model-url/model.mlmodel",
        @"https://improve-v5-resources-test-models-117097735164.s3-us-west-2.amazonaws.com/models/test/mlmodel/latest.tar.gz",
        @"https%3A%2F%2Fthis-is-a-181-char-long-string-already-percent-encoded-for-test-1234567890abcdefghijklmnopq.amazon.s3-us-west-2.amazonaws.com%2Fmodels%2Ftest%2Fmlmodel%2Flatest.tar.gz",
        @"https://github.com/improveai/ios-sdk/blob/master/Improve/Tests/ImproveUnitTests/model/this-is-a-200-char-long-model-url-for-test/1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijk/model.mlmodel",
        @"https://this-is-a-500-char-long-string-for-test--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------amazon.s3-us-east-1.amazonaws.com/models/test/mlmodel/latest.tar.gz"
    ];
    for (NSString *str in strings)
    {
        // Check output length
        NSURL *url = [NSURL URLWithString:str];
        NSString *modelName = [downloader modelFileNameFromURL:url];
        NSLog(@"%@", modelName);
        XCTAssert(modelName.length <= NAME_MAX);

        // Check hash consistency
        NSString *modelName2 = [downloader modelFileNameFromURL:url];
        XCTAssert([modelName isEqualToString:modelName2]);
    }
}

- (void)test256{
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:[NSURL URLWithString:@"www.dummyurl.com"]];
    NSString *remoteUrl = @"https://github.com/improveai/ios-sdk/blob/master/Improve/Tests/ImproveUnitTests/model/this-is-a-200-char-long-model-url-for-test/1234567890abcdefghijklmnopqrstuvwxyz1234567890abcdefghijk/model.mlmodel";
    NSString *modelName = [downloader modelFileNameFromURL:[NSURL URLWithString:remoteUrl]];
    NSLog(@"length = %lu, Model Name = %@", modelName.length, modelName);
}

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

@end
