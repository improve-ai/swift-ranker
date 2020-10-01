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
    NSString *modelURL = @"https://improve-v5-resources-prod-models-117097735164.s3-us-west-2.amazonaws.com/models/mindful/mlmodel/latest.tar.gz";
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [IMPModel modelWithContentsOfURL:[NSURL URLWithString:modelURL]
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
    NSArray *rankedVariants = [self.model sort:variants
                                       context:context];
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

@end
