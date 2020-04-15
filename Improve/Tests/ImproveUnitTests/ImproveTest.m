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

@interface IMPConfiguration ()
- (NSString *)generateHistoryId;
- (int)historyIdSize;
@end

@interface ImproveTest : XCTestCase

@end

@implementation ImproveTest {
    IMPConfiguration *config;
}

- (void)setUp {
    config = [IMPConfiguration configurationWithAPIKey:@"api_key_for_test"
                                            modelNames:@[@"test"]];
    [Improve configureWith:config];
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

- (void)testHistoryId {
    for (int i = 0; i < 10; i++)
    {
        NSString *historyId = [config generateHistoryId];
        NSLog(@"%@", historyId);
        XCTAssertNotNil(historyId);
        XCTAssert(historyId.length > [config historyIdSize] / 3 * 4);
    }
    XCTAssertNotNil(config.historyId);
}

@end
