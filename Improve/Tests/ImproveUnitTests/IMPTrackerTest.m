//
//  IMPTrackerTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 9/30/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPTracker.h"

@interface IMPTracker ()

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
        IMPTracker *tracker = [[IMPTracker alloc] initWithTrackURL:url];

        // Check initialization
        XCTAssertNotNil(tracker.historyId);

        // Check id shape
        NSString *historyId = tracker.historyId;
        NSLog(@"%@", historyId);
        XCTAssertNotNil(historyId);
        XCTAssert(historyId.length > 32 / 3 * 4);
    }
}

@end
