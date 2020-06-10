//
//  JSONFlattenerTest.m
//  FeatureHasherUnitTests
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPJSONFlattener.h"

@interface JSONFlattenerTest : XCTestCase

@end

@implementation JSONFlattenerTest

- (void)testVersusPythonOutput {
    NSArray *cases = @[
        @{@"in": @{@"a": @{@"b": @1}},
          @"out": @{@"a_b": @1}},
        @{@"in": @{@"a": @1, @"b": @[@1, @2], @"c": @{@"a": @"a", @"b": @[@1, @2, @3]}},
          @"out": @{@"a": @1, @"b_0": @1, @"b_1": @2, @"c_a": @"a",
                    @"c_b_0": @1, @"c_b_1": @2, @"c_b_2": @3}},
        @{@"in": @{
                  @"a": @1,
                  @"b": @2,
                  @"c": @[@{@"d": @[@2, @3, @4], @"e": @[@{@"f": @1, @"g": @2}]}]
        },
          @"out": @{
                  @"a": @1,
                  @"b": @2,
                  @"c_0_d_0": @2,
                  @"c_0_d_1": @3,
                  @"c_0_d_2": @4,
                  @"c_0_e_0_f": @1,
                  @"c_0_e_0_g": @2
          }},
        @{@"in": @{@"a": @1, @"b": @2, @"c": @{@"d": @3, @"e": @4}},
          @"out": @{@"a": @1, @"b": @2, @"c_d": @3, @"c_e": @4}},
        @{@"in": @{@"a": @0.5, @"c": @{@"d": @3.2}},
          @"out": @{@"a": @0.5, @"c_d": @3.2}},
        @{@"in": @{@"a": @0.8, @"b": @1.8},
          @"out": @{@"a": @0.8, @"b": @1.8}}
    ];

    IMPJSONFlattener *flattener = [[IMPJSONFlattener alloc] init];
    flattener.separator = @"_";
    for (NSDictionary *c in cases) {
        NSDictionary *input = c[@"in"];
        NSLog(@"in: %@", input);
        NSDictionary *output = [flattener flatten:input];
        NSLog(@"out: %@", output);
        NSDictionary *expectedOutp = c[@"out"];
        XCTAssert([output isEqualToDictionary:expectedOutp]);
    }
}

- (void)testFlattenWithNullSeparator {
    NSString *nulStr = @"\0";
    XCTAssert(nulStr.length == 1);

    IMPJSONFlattener *flattener = [[IMPJSONFlattener alloc] init];
    flattener.separator = nulStr;

    NSDictionary *input = @{@"game": @{@"team": @{@"user": @{@"score": @15}}}};
    NSDictionary *correctOut = @{@"game\0team\0user\0score": @15};
    NSDictionary *realOut = [flattener flatten:input];
    NSLog(@"%@", realOut);
    XCTAssert([realOut isEqualToDictionary:correctOut]);
}

- (void)testSpecialValues {
    NSDictionary *input = @{
        @"true": @YES,
        @"false": @NO,
        @"array": @[],
        @"dict": @{}
    };
    NSDictionary *correctOut = @{
        @"true": @1,
        @"false": @0,
        @"array": @-2,
        @"dict": @-3
    };

    IMPJSONFlattener *flattener = [[IMPJSONFlattener alloc] init];
    flattener.emptyDictionaryValue = @-3;
    flattener.emptyArrayValue = @-2;

    NSDictionary *realOut = [flattener flatten:input];
    NSLog(@"%@", realOut);
    XCTAssert([realOut isEqualToDictionary:correctOut]);
}

@end
