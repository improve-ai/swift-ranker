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

- (nullable NSString *)lastDecisionIdOfModel:(NSString *)modelName;

@end

@interface IMPDecision ()

@property (nonatomic, strong, readonly) NSString *id;

@property(nonatomic, strong) NSArray *scores;

@property(nonatomic, strong) NSDictionary *allGivens;

@property (nonatomic, readonly) int tracked;

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

- (void)testPeek {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    id best = [[decisionModel chooseFrom:[self variants]] peek];
    XCTAssertNotNil(best);
}

- (void)testGet_track_only_once {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    XCTAssertNotNil(decisionModel.tracker);
    
    IMPDecision *decision = [decisionModel chooseFrom:[self variants]];
    XCTAssertEqual(0, decision.tracked);
    
    int loop = 1000;
    for(int i = 0; i < loop; ++i) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [decision get];
        });
    }
    [NSThread sleepForTimeInterval:1];
    XCTAssertEqual(1, decision.tracked);
}

- (void)testGet_without_tracker {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    
    IMPDecision *decision = [decisionModel chooseFrom:[self variants]];
    XCTAssertEqual(0, decision.tracked);
    [decision get];
    XCTAssertEqual(1, decision.tracked);

    decision = [decisionModel chooseFrom:[self variants]];
    decisionModel.trackURL = nil;
    XCTAssertEqual(0, decision.tracked);
    [decision get];
    XCTAssertEqual(0, decision.tracked);
}

- (void)testGet_persist_decision_id {
    NSString *modelName = @"hello";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    IMPDecision *decision = [decisionModel chooseFrom:[self variants]];
    
    NSString *decisionIdBeforeGet = [decisionModel.tracker lastDecisionIdOfModel:modelName];
    
    [decision get];
    
    NSString *decisionIdAfterGet = [decisionModel.tracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(decision.id);
    XCTAssertEqualObjects(decision.id, decisionIdAfterGet);
    XCTAssertNotEqualObjects(decisionIdBeforeGet, decisionIdAfterGet);
    NSLog(@"decisionId: %@, %@, %@", decision.id, decisionIdBeforeGet, decisionIdAfterGet);
}

- (void)testAddReward_valid {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel chooseFrom:variants];
    XCTAssertNotNil([decision get]);
    [decision addReward:0.1];
}

- (void)testAddReward_before_get {
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
        IMPDecision *decision = [decisionModel chooseFrom:[self variants]];
        [decision addReward:0.1];
    } @catch(NSException *e) {
        NSLog(@"Decision.addReward() can't be called prior to get()");
        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testAddReward_nil_trackURL {
    @try {
        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello" trackURL:nil trackApiKey:nil];
        IMPDecision *decision = [decisionModel chooseFrom:variants];
        [decision get];
        [decision addReward:0.1];
    } @catch(NSException *e) {
        NSLog(@"trackURL of the underlying DecisionModel can't be nil");
        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testAddReward_NaN {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel chooseFrom:variants];
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
    IMPDecision *decision = [decisionModel chooseFrom:variants];
    [decision get];

    @try {
        [decision addReward:(1.0/0.0)];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testAddReward_negative_infinity {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [decisionModel chooseFrom:variants];
    [decision get];

    @try {
        [decision addReward:(-1.0/0.0)];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

@end
