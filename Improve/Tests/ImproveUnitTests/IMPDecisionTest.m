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

- (void)testAddReward {
    
}

- (void)testAddReward_Before_Get {
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:model];
    [decision addReward:0.1];
}


@end
