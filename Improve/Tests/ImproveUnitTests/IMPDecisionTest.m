//
//  IMPDecisionTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 5/7/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionModel.h"
#import "IMPDecision.h"
#import "TestUtils.h"
#import "IMPConstants.h"

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

- (void)testChooseFromNilVariants {
    NSArray *variants = nil;
    NSDictionary *context = @{@"language": @"cowboy"};
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    decisionModel.trackURL = [NSURL URLWithString:@""];
    
    NSString *greeting = [[[decisionModel given:context] chooseFrom:variants] get];
    XCTAssertNil(greeting);
}

- (void)testChooseFromEmptyVariants {
    NSArray *variants = @[];
    NSDictionary *context = @{@"language": @"cowboy"};
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    XCTAssertNotNil(decisionModel);
    
    NSString *greeting = [[[decisionModel given:context] chooseFrom:variants] get];
    IMPLog("greeting=%@", greeting);
    XCTAssertNil(greeting);
    
    NSURL *url = [[TestUtils bundle] URLForResource:@"TestModel"
                                      withExtension:@"mlmodelc"];
    [decisionModel loadAsync:url completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
        XCTAssertNil(error);
        
        NSString *greeting = [[compiledModel chooseFrom:variants] get];
        XCTAssertNil(greeting);
    }];
}

- (void)testGetWithoutChooseFrom {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:decisionModel];
    XCTAssertNil([decision get]);
}

// Always pass
// Just a convenient method to test that an error log is printed when
// [IMPDecision get] is called but tracker is not set for the model
- (void)testGetWithoutTracker {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *givens = @{@"language": @"cowboy"};
    
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    [[[model given:givens] chooseFrom:variants] get];
    
    [[[model given:givens] chooseFrom:@[]] get];
    
    model.trackURL = [NSURL URLWithString:kTrackerURL];
    [[[model given:givens] chooseFrom:@[]] get];
}

- (void)testAddReward_valid {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
    [[decision chooseFrom:variants] get];
    [decision addReward:0.1];
    
}

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

- (void)testAddReward_nil_trackURL {
    @try {
        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello" trackURL:nil];
        IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
        [[decision chooseFrom:variants] get];
        [decision addReward:0.1];
    } @catch(NSException *e) {
        NSLog(@"trackURL of the underlying DecisionModel can't be nil");
        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testAddReward_nil_trackURL_after_get {
    @try {
        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
        IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
        [[decision chooseFrom:variants] get];
        
        // set trackURL to nil after calling get
        model.trackURL = nil;
        
        [decision addReward:0.1];
    } @catch(NSException *e) {
        NSLog(@"trackURL of the underlying DecisionModel can't be nil");
        XCTAssertEqualObjects(IMPIllegalStateException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

@end
