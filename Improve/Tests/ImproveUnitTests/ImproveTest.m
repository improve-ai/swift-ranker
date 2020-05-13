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
    // TODO test nil api key
    config = [IMPConfiguration configurationWithAPIKey:@"api_key_for_test"];
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
    NSArray *output = [self combinationsFromVariants:variantMap];
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
    NSArray *rankedVariants = [[Improve instance] sort:variants
                                               context:context
                                                domain:modelName];
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

- (NSArray<NSDictionary*> *) combinationsFromVariants:(NSDictionary<NSString*, NSArray*> *)variantMap
{
    // Store keys to preserve it's order during iteration
    NSArray *keys = variantMap.allKeys;

    // NSString: NSNumber, options count for each key
    NSUInteger *counts = calloc(keys.count, sizeof(NSUInteger));
    // Numbe of all possible variant combinations
    NSUInteger factorial = 1;
    for (NSUInteger i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSUInteger count = [variantMap[key] count];
        counts[i] = count;
        factorial *= count;
    }

    /* A series of indexes identifying a particular combination of elements
     selected in the map for each key */
    NSUInteger *indexes = calloc(variantMap.count, sizeof(NSUInteger));

    NSMutableArray *combos = [NSMutableArray arrayWithCapacity:factorial];

    BOOL finished = NO;
    while (!finished) {
        NSMutableDictionary *variant = [NSMutableDictionary dictionaryWithCapacity:keys.count];
        BOOL shouldIncreaseIndex = YES;
        for (NSUInteger i = 0; i < keys.count; i++) {
            NSString *key = keys[i];
            NSArray *options = variantMap[key];
            variant[key] = options[indexes[i]];

            if (shouldIncreaseIndex) {
                indexes[i] += 1;
            }
            if (indexes[i] >= counts[i]) {
                if (i == keys.count - 1) {
                    finished = YES;
                } else {
                    indexes[i] = 0;
                }
            } else {
                shouldIncreaseIndex = NO;
            }
        }
        [combos addObject:variant];
    }

    free(counts);
    free(indexes);

    return combos;
}

@end
