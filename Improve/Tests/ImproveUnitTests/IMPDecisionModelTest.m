//
//  IMPDecisionModelTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/29/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionModel.h"
#import "TestUtils.h"
#import "IMPScoredObject.h"


@interface IMPDecisionModelTest : XCTestCase
@property(nonatomic, strong) IMPDecisionModel *model;
@end

@implementation IMPDecisionModelTest

- (void)setUp {
//    NSURL *modelURL2 = [[TestUtils bundle] URLForResource:@"TestModel" withExtension:@"mlmodel"];
//    NSLog(@"%@", modelURL2);
//    NSLog(@"%@", [TestUtils bundle].bundlePath);
    NSURL *modelURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/Mindful new Oct 2/improve-messages-2.0-3.mlmodel"];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [IMPDecisionModel modelWithContentsOfURL:modelURL
                                 cacheMaxAge:10
                           completionHandler:^(IMPDecisionModel * _Nullable model, NSError * _Nullable error) {
        XCTAssert([NSThread isMainThread]);

        if (error) {
            NSLog(@"Error: %@", error);
        }
        XCTAssertNotNil(model);
        self.model = model;
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:300.];
}

- (void)testScore
{
    NSArray *scores = [self.model score:[TestUtils defaultTrials]
                                context:[TestUtils defaultContext]];
    XCTAssertNotNil(scores);

    NSArray *expectedScores = [TestUtils defaultPredictions];
    XCTAssert(scores.count == expectedScores.count);

    for (int i = 0; i < scores.count; i++)
    {
        double score = [scores[i] doubleValue];
        double expectedScore = [expectedScores[i] doubleValue];
        NSLog(@"score: %g expected: %g", score, expectedScore);
        XCTAssert(isEqualRough(score, expectedScore));
    }
}

@end

