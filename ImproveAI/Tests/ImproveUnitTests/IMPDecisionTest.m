//
//  IMPDecisionTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 5/7/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionTracker.h"
#import "IMPDecisionModel.h"
#import "IMPDecision.h"
#import "TestUtils.h"
#import "IMPConstants.h"

@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

@end

@interface IMPDecisionTracker ()

+ (nullable NSString *)lastDecisionIdOfModel:(NSString *)modelName;

@end

@interface IMPDecision ()

@property(nonatomic, strong) NSArray *scores;

@property(nonatomic, strong) NSDictionary *allGivens;

@end

@interface IMPDecisionTest : XCTestCase

@end

@implementation IMPDecisionTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSArray *)variants {
    return @[@"Hello World", @"Howdy World", @"Hi World"];
}

- (void)testBest {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    XCTAssertEqualObjects(@"Hello World", decision.best);
}

- (void)testPeek {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    XCTAssertEqualObjects(@"Hello World", [decision peek]);
}

- (void)testGet {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    XCTAssertEqualObjects(@"Hello World", [decision get]);
    NSLog(@"ranked: %@", decision.ranked);
}

- (void)testGet_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    NSString *d0 = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decision get];
    NSString *d1 = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decision get];
    NSString *d2 = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(d0);
    XCTAssertNotNil(d1);
    XCTAssertNotEqualObjects(d0, d1);
    XCTAssertEqualObjects(d1, d2);
    XCTAssertEqualObjects(@"Hello World", [decision get]);
    NSLog(@"decision id: %@, %@, %@", d0, d1, d2);
}

- (void)testRanked {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    XCTAssertEqualObjects([self variants], decision.ranked);
}

- (void)testTrack {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    XCTAssertNil(decision.id);
    [decision track];
    XCTAssertTrue([decision.id length] > 0);
}

- (void)testTrack_nil_trackURL {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    decisionModel.trackURL = nil;
    @try {
        [decision track];
        XCTFail("trackURL can't be nil when calling track().");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"trackURL of the underlying DecisionModel is nil!", e.reason);
    }
}

- (void)testTrack_called_twice {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:[self variants]];
    [decision track];
    @try {
        [decision track];
        XCTFail("trackURL can't be nil when calling track().");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"the decision is already tracked!", e.reason);
    }
}

- (void)testAddReward {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:variants];
    XCTAssertNotNil([decision get]);
    [decision addReward:0.1];
}

- (void)testAddReward_before_track {
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
        IMPDecision *decision = [decisionModel decide:[self variants]];
        [decision addReward:0.1];
        XCTFail(@"addReward() can't be called before track().");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"addReward() can't be called before track().", e.reason);
    }
}

- (void)testAddReward_nil_trackURL {
    @try {
        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
        IMPDecision *decision = [decisionModel decide:variants];
        [decision track];
        decisionModel.trackURL = nil;
        [decision addReward:0.1];
        XCTFail(@"trackURL of the underlying DecisionModel can't be nil when calling addReward.");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"trackURL can't be nil when calling addReward()", e.reason);
    }
}

- (void)testAddReward_NaN {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:variants];
    [decision get];

    @try {
        [decision addReward:NAN];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testAddReward_positive_infinity {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:variants];
    [decision track];

    @try {
        [decision addReward:(1.0/0.0)];
        XCTFail(@"An exception should have been thrown.");
    } @catch(NSException *e) {
        XCTAssertTrue([e.reason hasPrefix:@"invalid reward"]);
    }
}

- (void)testAddReward_negative_infinity {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel decide:variants];
    [decision track];

    @try {
        [decision addReward:(-1.0/0.0)];
        XCTFail(@"An exception should have been thrown.");
    } @catch(NSException *e) {
        XCTAssertTrue([e.reason hasPrefix:@"invalid reward"]);
    }
}

@end
