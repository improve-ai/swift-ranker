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

@interface IMPDecision ()

@property(nonatomic, readonly, nullable) id best;

@property(nonatomic, readonly) BOOL chosen;

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

- (void)testGivens {
//    NSDictionary *givens = @{@"language": @"cowboy"};
//    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [decisionModel given:givens];
//    XCTAssertNotNil(decision.givens);
//    XCTAssertEqualObjects(givens, decision.givens);
}

- (void)testGivens_setter_after_chooseFrom {
//    NSDictionary *givens = @{@"language": @"cowboy"};
//    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [decisionModel chooseFrom:[self variants]];
//    XCTAssertNil(decision.givens);
//    decision.givens = givens;
//    XCTAssertNil(decision.givens);
}

//- (void)testChooseFrom {
//    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:decisionModel];
//    XCTAssertNil(decision.best);
//    XCTAssertFalse(decision.chosen);
//    XCTAssertNil(decision.allGivens);
//    XCTAssertNil(decision.scores);
//    [decision chooseFrom:[self variants]];
//    XCTAssertNotNil(decision.best);
//    XCTAssertTrue(decision.chosen);
//    XCTAssertNotNil(decision.allGivens);
//    XCTAssertNotNil(decision.scores);
//}

//- (void)testChooseFrom_nil_variants {
//    NSArray *variants = nil;
//    NSDictionary *givens = @{@"language": @"cowboy"};
//    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    @try {
//        [[decisionModel given:givens] chooseFrom:variants];
//    } @catch(NSException *e) {
//        XCTAssertEqual(NSInvalidArgumentException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

//- (void)testChooseFrom_empty_variants {
//    NSArray *variants = @[];
//    NSDictionary *context = @{@"language": @"cowboy"};
//    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//
//    @try {
//        [[decisionModel given:context] chooseFrom:variants];
//    } @catch(NSException *e) {
//        XCTAssertEqual(NSInvalidArgumentException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

- (void)testPeek_before_chooseFrom {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:decisionModel];
    @try {
        [decision peek];
    } @catch(NSException *e) {
        XCTAssertEqual(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testPeek {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    [[decisionModel chooseFrom:[self variants]] peek];
}

- (void)testGet_before_chooseFrom {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:decisionModel];
    @try {
        [decision get];
    } @catch(NSException *e) {
        XCTAssertEqual(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
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
    [NSThread sleepForTimeInterval:0.5];
    XCTAssertEqual(1, decision.tracked);
}

//- (void)testGet_without_tracker {
//    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//    XCTAssertEqual(0, decision.tracked);
//    [[decision chooseFrom:[self variants]] get];
//    XCTAssertEqual(1, decision.tracked);
//
//    decision = [[IMPDecision alloc] initWithModel:model];
//    model.trackURL = nil;
//    XCTAssertEqual(0, decision.tracked);
//    [[decision chooseFrom:[self variants]] get];
//    XCTAssertEqual(0, decision.tracked);
//}

//- (void)testAddReward_valid {
//    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//    [[decision chooseFrom:variants] get];
//    [decision addReward:0.1];
//
//}

- (void)testAddReward_before_get {
    @try {
        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
        IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
        [decision addReward:0.1];
    } @catch(NSException *e) {
        NSLog(@"Decision.addReward() can't be called prior to get()");
        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

//- (void)testAddReward_nil_trackURL {
//    @try {
//        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello" trackURL:nil trackApiKey:nil];
//        IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//        [[decision chooseFrom:variants] get];
//        [decision addReward:0.1];
//    } @catch(NSException *e) {
//        NSLog(@"trackURL of the underlying DecisionModel can't be nil");
//        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

//- (void)testAddReward_nil_trackURL_after_get {
//    @try {
//        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//        IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//        [[decision chooseFrom:variants] get];
//
//        // set trackURL to nil after calling get
//        model.trackURL = nil;
//
//        [decision addReward:0.1];
//    } @catch(NSException *e) {
//        NSLog(@"trackURL of the underlying DecisionModel can't be nil");
//        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

//- (void)testAddReward_NaN {
//    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//    [[decision chooseFrom:variants] get];
//
//    @try {
//        [decision addReward:NAN];
//    } @catch(NSException *e) {
//        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

//- (void)testAddReward_positive_infinity {
//    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//    [[decision chooseFrom:variants] get];
//
//    @try {
//        [decision addReward:(1.0/0.0)];
//    } @catch(NSException *e) {
//        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}

//- (void)testAddReward_negative_infinity {
//    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
//    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
//    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
//    [[decision chooseFrom:variants] get];
//
//    @try {
//        [decision addReward:(-1.0/0.0)];
//    } @catch(NSException *e) {
//        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
//        return ;
//    }
//    XCTFail(@"An exception should have been thrown.");
//}


@end
