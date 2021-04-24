//
//  IMPDecisionTrackerTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/29/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionTracker.h"

@interface IMPDecisionTracker ()

- (id)sampleVariantOf:(NSArray *)variants ignoreTrackedCount:(NSUInteger)trackedVariantsCount;

@end

@interface IMPDecisionTracker ()

- (NSString *)generateHistoryId;

- (NSString *)historyId;

@end

@interface IMPTrackerTest : XCTestCase

@end

@implementation IMPTrackerTest

- (void)testHistoryId {
    // Generation
    for (int i = 0; i < 10; i++)
    {
        // URL doesn't matter here
        NSURL *url = [NSURL URLWithString:@""];
        IMPDecisionTracker *tracker = [[IMPDecisionTracker alloc] initWithTrackURL:url];

        // Check initialization
        XCTAssertNotNil(tracker.historyId);

        // Check id shape
        NSString *historyId = tracker.historyId;
        NSLog(@"historyId: %@", historyId);
        XCTAssertNotNil(historyId);
        XCTAssert(historyId.length > 32 / 3 * 4);
    }
}

- (void)testSampleVariant {
    NSURL *url = [NSURL URLWithString:@""];
    
    NSArray *variants = @[@1, @2, @3, @4, @5];
    NSUInteger trackedCount = 4;
    
    IMPDecisionTracker *tracker = [[IMPDecisionTracker alloc] initWithTrackURL:url];
    id sampleVariant = [tracker sampleVariantOf:variants ignoreTrackedCount:trackedCount];
    XCTAssertEqual([sampleVariant intValue], 5);
    
    trackedCount = 5;
    sampleVariant = [tracker sampleVariantOf:variants ignoreTrackedCount:trackedCount];
    XCTAssertNil(sampleVariant);
}

@end
