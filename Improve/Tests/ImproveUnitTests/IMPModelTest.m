//
//  IMPModelTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 9/30/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPModel.h"
#import "TestUtils.h"
#import "IMPScoredObject.h"


@interface IMPModelTest : XCTestCase
@property(nonatomic, strong) IMPModel *model;
@end

@implementation IMPModelTest

- (void)setUp {
//    NSURL *modelURL2 = [[TestUtils bundle] URLForResource:@"TestModel" withExtension:@"mlmodel"];
//    NSLog(@"%@", modelURL2);
//    NSLog(@"%@", [TestUtils bundle].bundlePath);
    NSURL *modelURL = [NSURL fileURLWithPath:@"/Users/vk/Dev/_PROJECTS_/ImproveAI-SKLearnObjC/test models/Mindful new Oct 2/improve-messages-2.0-3.mlmodel"];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [IMPModel modelWithContentsOfURL:modelURL
                         cacheMaxAge:10
                   completionHandler:^(IMPModel * _Nullable model, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error: %@", error);
        }
        XCTAssertNotNil(model);
        self.model = model;
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:300.];
}

- (void)testRank {
    NSArray *variants = [TestUtils defaultTrials];
    NSDictionary *context = @{};
    NSArray *rankedVariants = [self.model sort:variants context:context];
    XCTAssertNotNil(rankedVariants);

    NSArray *scores = [TestUtils defaultPredictions];
    NSMutableArray *xgboostScored = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSUInteger i = 0; i < variants.count; i++) {
        double xgbScore = [scores[i] doubleValue];
        [xgboostScored addObject:[IMPScoredObject withScore:xgbScore
                                                     object:variants[i]]];
    }
    [xgboostScored sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];
    NSMutableArray *expectedRankedVariants = [NSMutableArray arrayWithCapacity:xgboostScored.count];
    for (NSUInteger i = 0; i < xgboostScored.count; i++) {
        [expectedRankedVariants addObject:[xgboostScored[i] object]];
    }
    NSLog(@"Ranked: %@", rankedVariants);
    NSLog(@"Expected: %@", expectedRankedVariants);
    XCTAssert([rankedVariants isEqualToArray:expectedRankedVariants]);
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
