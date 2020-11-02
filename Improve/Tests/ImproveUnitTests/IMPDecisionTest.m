//
//  IMPDecisionTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/29/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecision.h"
#import "IMPDecisionTracker.h"

@interface IMPDecisionTest : XCTestCase

@end

@implementation IMPDecisionTest

- (void)testGettersSetters
{
    NSURL *trackURL = [NSURL URLWithString:@""];
    IMPDecisionTracker *tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL];

    NSArray *variants = @[
        @"Mercury",
        @"Venus",
        @"Earth",
        @"Mars",
        @"Jupiter",
        @"Saturn",
        @"Uranus",
        @"Neptune"
    ];
    NSString *modelName = @"megamodel";
    NSDictionary *context = @{@"version": @323, @"day": @"friday"};

    IMPDecision *decision1 = [[IMPDecision alloc] initWithRankedVariants:variants modelName:modelName tracker:tracker context:context];

    // Basic
    XCTAssert([decision1.variants isEqualToArray:variants]);
    XCTAssert([decision1.ranked isEqualToArray:variants]);
    XCTAssert([decision1.best isEqual:variants.firstObject]);
    XCTAssert([decision1.modelName isEqualToString:modelName]);
    XCTAssert([decision1.context isEqualToDictionary:context]);

    // Immutability
    XCTAssertFalse([decision1.variants isKindOfClass:NSMutableArray.class]);
    XCTAssertFalse([decision1.scores isKindOfClass:NSMutableArray.class]);
    XCTAssertFalse([decision1.ranked isKindOfClass:NSMutableArray.class]);
    XCTAssertFalse([decision1.scored isKindOfClass:NSMutableArray.class]);
    XCTAssertFalse([decision1.context isKindOfClass:NSMutableDictionary.class]);

    // TODO: the same tests with model
}

- (void)testNilContext
{
    NSURL *trackURL = [NSURL URLWithString:@""];
    IMPDecisionTracker *tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL];

    NSArray *variants = @[
        @"A",
        @"a",
        @"b",
        @"c",
        @"d"
    ];
    NSString *modelName = @"my_model";

    IMPDecision *decision = [[IMPDecision alloc] initWithRankedVariants:variants modelName:modelName tracker:tracker context:nil];
    XCTAssert([decision.context isEqualToDictionary:[IMPDecision simpleContext]]);
}

@end
