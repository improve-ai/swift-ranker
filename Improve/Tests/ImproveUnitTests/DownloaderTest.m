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

- (NSURL *)compileModelAtURL:(NSURL *)modelDefinitionURL error:(NSError **)error;

@end

@implementation DownloaderTest

- (void)testCompile {
    NSURL *modelDefinitionURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/XGBoost example/model-4/Chooser.mlmodel"];
    XCTAssertNotNil(modelDefinitionURL);

    // Url isn't used here.
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:modelDefinitionURL];

    NSURL *compiledURL;
    for (NSUInteger i = 0; i < 3; i++) // Loop to check overwriting.
    {
        NSError *err;
        compiledURL = [downloader compileModelAtURL:modelDefinitionURL error:&err];
        if (!compiledURL) { NSLog(@"Compilation error: %@", err); }
        XCTAssertNotNil(compiledURL);
        NSLog(@"%@", compiledURL);
    }
    if ([[NSFileManager defaultManager] removeItemAtURL:compiledURL error:nil]) {
        NSLog(@"Deleted.");
    }
}

- (void)testDownload {
    NSURL *remoteURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/XGBoost example/model-4/Chooser.mlmodel"];
    XCTAssertNotNil(remoteURL);
    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:remoteURL];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Model downloaded"];
    [downloader loadWithCompletion:^(NSURL * _Nullable localURL, NSError * _Nullable error) {
        if (error != nil) {
            XCTFail(@"Downloading error: %@", error);
        }
        NSLog(@"%@", localURL);

        // Cleenup
        if ([[NSFileManager defaultManager] removeItemAtURL:localURL error:nil]) {
            NSLog(@"Deleted.");
        }

        [expectation fulfill];
    }];

    [self waitForExpectations:@[expectation] timeout:60.0];
}

@end
