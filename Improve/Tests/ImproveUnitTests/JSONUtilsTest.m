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

- (void)testVariantToCanonical {
    NSNumber *numb = [NSNumber numberWithDouble:3];
    XCTAssert([[IMPJSONUtils variantToCanonical:numb] isEqualToString:[numb description]]);
    
    NSNumber *aBool = [NSNumber numberWithBool:NO];
    XCTAssert([[IMPJSONUtils variantToCanonical:aBool] isEqualToString:[aBool description]]);
    
    NSDictionary *goodDict = @{@"id": @"007", @"pass": @"xxx"};
    XCTAssert([[IMPJSONUtils variantToCanonical:goodDict] isEqualToString:@"007"]);
    
    NSDictionary *badDict = @{@"message": @{@"text": @"Massage your temples."}};
    XCTAssertThrows([IMPJSONUtils variantToCanonical:badDict]);
}

@end
