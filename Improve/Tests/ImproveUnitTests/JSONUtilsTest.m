//
//  JSONUtilsTest.m
//  MLUnitTests
//
//  Created by Vladimir on 1/22/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPJSONUtils.h"

@interface JSONUtilsTest : XCTestCase

@end

@implementation JSONUtilsTest

- (void)testPropertiesToFeatures {
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  NSURL *url = [bundle URLForResource:@"propertiesToFeatures" withExtension:@"json"];
  XCTAssertNotNil(url);
  NSData *data = [NSData dataWithContentsOfURL:url];
  XCTAssertNotNil(data);
  NSError *error;
  NSArray *cases = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
  XCTAssertNil(error);
  XCTAssertNotNil(cases);

  for (NSDictionary *testCase in cases) {
    NSLog(@"%@", testCase);
    
    NSDictionary *input = testCase[@"in"];
    NSDictionary *output = [IMPJSONUtils propertiesToFeatures:input];
    NSDictionary *expectedOutput = testCase[@"out"];

    XCTAssert([output isEqualToDictionary:expectedOutput]);
  }
  
}

@end
