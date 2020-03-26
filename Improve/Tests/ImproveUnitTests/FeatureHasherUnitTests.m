//
//  FeatureHasherUnitTests.m
//  FeatureHasherUnitTests
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPFeatureHasher.h"
#import "TestUtils.h"
#import "IMPJSONUtils.h"


@interface FeatureHasherUnitTests : XCTestCase

@end

@implementation FeatureHasherUnitTests

- (void)testBasics {
    NSArray *table = [IMPJSONUtils objectFromString:@"[[-6, 4], [[[-1], [2, 0.0]], [[-1], [0.0, 0.0]], [[2], [3.0, 0.0, 2.0, 0.0, 1.0, 0.0]], [[2], [0.0, 100.0, 0.0, 10.0, 0.0, 1.0]], [[-1], [3, 0.0]], [[-1], [1, 0.0]]]]"];
    XCTAssertNotNil(table);
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithTable:table seed:0];
    NSArray *tests = @[
        @{@"arrays": @[@0, @1, @2]},
        @{@"letters": @"a"},
        @{@"letters": @"b"},
        @{@"letters": @"c"},
        @{@"noise": @"a"},
        @{@"noise": @"b"},
        @{@"noise": @"c"},
        @{@"numbers": @1},
        @{@"numbers": @2},
        @{@"numbers": @3},
        @{@"numbers": @YES},
        @{@"numbers": @NO},
        @{@"null": [NSNull null]}
    ];
    /*

     {5: 0.0, 0: 1.0, 4: 2.0}
     {2: 1.0}
     {2: 2.0}
     {2: 3.0}
     {3: -0.6977207556303153}
     {3: -0.10103788565428871}
     {3: -61.516331515247266}
     {1: 1.0}
     {1: 2.0}
     {1: 3.0}
     {1: 1.0}
     {1: 0.0}
     {}
     */
    NSArray *checks = @[
        @{@5: @0.0, @0: @1.0, @4: @2.0},
        @{@2: @1.0},
        @{@2: @2.0},
        @{@2: @3.0},
        @{@3: @"~noise#"},
        @{@3: @"~noise#"},
        @{@3: @"~noise#"},
        @{@1: @1.0},
        @{@1: @2.0},
        @{@1: @3.0},
        @{@1: @1.0},
        @{@1: @0.0},
        @{}
    ];
    XCTAssert(tests.count == checks.count);
    for (NSUInteger i = 0; i < tests.count; i++)
    {
        NSDictionary *encoded = [hasher encodeFeatures:tests[i]];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        XCTAssert(encoded.count == check.count);
        for (NSString *key in check) {
            id expectedVal = check[key];
            if ([expectedVal isKindOfClass:NSString.class]
                && [expectedVal isEqualToString:@"~noise#"]) {
                // Just make sure that value exists
                XCTAssert([encoded[key] isKindOfClass:NSNumber.class]);
            } else {
                XCTAssert([encoded[key] isEqual:expectedVal]);
            }
        }
    }
}

@end
