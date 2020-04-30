//
//  ImproveTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Improve.h"
#import "IMPModelBundle.h"
#import "TestUtils.h"
#import "IMPScoredObject.h"

@interface Improve ()
- (NSArray<NSDictionary*> *)combinationsFromVariants:(NSDictionary<NSString*, NSArray*> *)variantMap;
- (NSMutableDictionary<NSString*, IMPModelBundle*> *)modelBundlesByName;
@end

@interface IMPConfiguration ()
- (NSString *)generateHistoryId;
- (int)historyIdSize;
@end

@interface ImproveTest : XCTestCase

@end

@implementation ImproveTest {
    IMPConfiguration *config;
}

- (void)setUp {
    config = [IMPConfiguration configurationWithAPIKey:@"api_key_for_test"
                                           projectName:@"test"];
    [Improve configureWith:config];
}

- (void)testCombinations {
    NSDictionary *variantMap = @{
        @"a": @[@1, @2, @3],
        @"b": @[@11, @12]
    };
    NSArray *expectedOutput = @[
        @{@"a": @1, @"b": @11},
        @{@"a": @2, @"b": @11},
        @{@"a": @3, @"b": @11},
        @{@"a": @1, @"b": @12},
        @{@"a": @2, @"b": @12},
        @{@"a": @3, @"b": @12}
    ];
    NSArray *output = [[Improve instance] combinationsFromVariants:variantMap];
    NSLog(@"%@", output);
    XCTAssert([output isEqualToArray:expectedOutput]);
}

- (void)testHistoryId {
    for (int i = 0; i < 10; i++)
    {
        NSString *historyId = [config generateHistoryId];
        NSLog(@"%@", historyId);
        XCTAssertNotNil(historyId);
        XCTAssert(historyId.length > [config historyIdSize] / 3 * 4);
    }
    XCTAssertNotNil(config.historyId);
}

- (void)testRankWithModelName:(NSString *)modelName
{
    NSArray *variants = [TestUtils defaultTrials];
    NSDictionary *context = @{};
    NSArray *rankedVariants = [[Improve instance] rank:variants
                                                action:modelName
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

- (void)testModelLoadingAndDecisions {
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Stupidly waiting for models to load"];
    NSLog(@"Waiting for models to load...");
    NSTimeInterval seconds = 30;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        NSDictionary *models = [[Improve instance] modelBundlesByName];
        NSLog(@"Finish waiting.\nLoaded models:\n%@", models);
        XCTAssertNotNil(models[@"default"]);

        /* Note: in order to test model with rank we need better test trials to
         allow predictions without noise. */
        //[self testRankWithModelName:@"model2"];

        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation] timeout:(seconds + 5)];
}

@end
