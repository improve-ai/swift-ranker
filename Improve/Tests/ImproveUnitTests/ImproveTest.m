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
#import "NSArray+Random.h"

// Disclose private interface for test
@interface Improve ()
@property (strong, atomic) NSString *historyId;
- (NSString *) generateHistoryId;
@end

@interface ImproveTest : XCTestCase

@end

@implementation ImproveTest {
}

- (void)setUp {
    Improve *defaultInstance = [Improve instance];
    [defaultInstance initializeWithApiKey:@"xScYgcHJ3Y2hwx7oh5x02NcCTwqBonnumTeRHThI" modelBundleURL: @"https://improve-v5-resources-prod-models-117097735164.s3-us-west-2.amazonaws.com/models/mindful/mlmodel/latest.tar.gz"];
    defaultInstance.maxModelsStaleAge = 10;
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
    // Generation
    for (int i = 0; i < 10; i++)
    {
        NSString *historyId = [[Improve instance] generateHistoryId];
        NSLog(@"%@", historyId);
        XCTAssertNotNil(historyId);
        XCTAssert(historyId.length > 32 / 3 * 4);
    }
    // Initialization
    XCTAssertNotNil([Improve instance].historyId);
}

- (void)testRankWithModelName:(NSString *)modelName
{
    NSArray *variants = [TestUtils defaultTrials];
    NSDictionary *context = @{};
    NSArray *rankedVariants = [[Improve instance] sort:@"test"
                                              variants:variants
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
    Improve *improve = [Improve instance];
    NSLog(@"Waiting for models to load...");
    XCTestExpectation *onReadyExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expects onReady block to be called"];
    [improve onReady:^{
        [onReadyExpectation fulfill];
    }];

    [self waitForExpectations:@[onReadyExpectation] timeout:180];
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
