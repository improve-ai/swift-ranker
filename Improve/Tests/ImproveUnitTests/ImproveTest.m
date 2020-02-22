//
//  ImproveTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Improve.h"

@interface Improve ()
- (NSArray<NSDictionary*> *) combinationsFromVariants:(NSDictionary<NSString*, NSArray*> *)variantMap;
@end

@interface ImproveTest : XCTestCase

@end

@implementation ImproveTest

- (void)setUp {
    [Improve instanceWithApiKey:@"api_key_for_test"];
}

- (void)testCombinations {
    NSDictionary *variantMap = @{
        @"a": @[@1, @2, @3],
        @"b": @[@11, @12]
    };
    NSArray *expectedOutput = @[
        @{@"a": @1, @"b": @11},
        @{@"a": @2, @"b": @11},
        @{@"a": @3, @"b": @11},
        @{@"a": @1, @"b": @12},
        @{@"a": @2, @"b": @12},
        @{@"a": @3, @"b": @12}
    ];
    NSArray *output = [[Improve instance] combinationsFromVariants:variantMap];
    NSLog(@"%@", output);
    XCTAssert([output isEqualToArray:expectedOutput]);
}

@end
