//
//  DownloaderTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/10/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPModelDownloader.h"

@interface DownloaderTest : XCTestCase

@end

@interface IMPModelDownloader ()

- (BOOL)compileModelAtURL:(NSURL *)modelDefinitionURL
                    toURL:(NSURL *)destURL
                    error:(NSError **)error;

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
    NSURL *remoteURL = [NSURL URLWithString:@"https://d2pq40dxlsc486.cloudfront.net/myproject/model.tar.gz"];
    XCTAssertNotNil(remoteURL);
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:remoteURL];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader loadWithCompletion:^(NSArray *modelBundles, NSError *error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        XCTAssert(modelBundles.count > 0);
        NSLog(@"Model bundle: %@", modelBundles);

        // Cleenup
//        NSURL *folderURL = bundle.modelURL.URLByDeletingLastPathComponent;
//        if ([[NSFileManager defaultManager] removeItemAtURL:folderURL error:nil]) {
//            NSLog(@"Deleted.");
//        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:60.0];
}

- (void)testCacheAge {
    // TODO: test with models and without models
    NSTimeInterval age = [IMPModelDownloader cachedModelsAge];
    NSLog(@"cachedModelsAge: %f", age);
    XCTAssert(age > 0);
}

@end
