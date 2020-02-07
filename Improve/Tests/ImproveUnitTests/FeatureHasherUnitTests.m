//
//  FeatureHasherUnitTests.m
//  FeatureHasherUnitTests
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPFeatureHasher.h"
#import "MLMultiArray+NSArray.h"
#import "NSArray+Multidimensional.h"
#import "TestUtils.h"

@interface FeatureHasherUnitTests : XCTestCase

@end

@implementation FeatureHasherUnitTests

- (void)testBasics {
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithNumberOfFeatures:10
                                                                    alternateSign:true];
    NSArray *features = @[@{@"dog": @1, @"cat": @2, @"elephant": @4},
                          @{@"dog": @2, @"run": @5}];
    IMPMatrix *output = [hasher transform:features];
    double expectedOutput[2][10] = {
        {0, 0, -4, -1, 0, 0, 0, 0, 0, 2},
        {0, 0, 0, -2, -5, 0, 0, 0, 0, 0}
    };

    XCTAssert(isEqualRough(20, output.buffer, *expectedOutput));
}

- (void)testPythonCases {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSURL *url = [bundle URLForResource:@"hasher" withExtension:@"json"];
    XCTAssertNotNil(url);
    NSData *data = [NSData dataWithContentsOfURL:url];
    XCTAssertNotNil(data);
    NSError *error;
    NSArray *cases = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(cases);

    NSLog(@"Test cases: %ld", cases.count);

    for (NSDictionary *testCase in cases) {
        NSDictionary *input = testCase[@"input"];
        NSNumber *numberOfFeatures = input[@"n_features"];
        NSNumber *shouldAlternateSign = input[@"alternate_sign"];
        NSArray *x = input[@"x"];

        IMPFeatureHasher *hasher
        = [[IMPFeatureHasher alloc] initWithNumberOfFeatures:numberOfFeatures.unsignedIntegerValue
                                               alternateSign:shouldAlternateSign.boolValue];
        IMPMatrix *output = [hasher transform:x];

        NSArray *expectedOutput = testCase[@"output"];
        NSLog(@"%@", expectedOutput);

        XCTAssert([[output aNSArray] isEqualToArray:expectedOutput]);
    }
}

@end
