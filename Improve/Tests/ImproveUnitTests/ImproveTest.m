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

NSString *const kTrainingInstance = @"training_tests";

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
    [[Improve instance] initializeWithApiKey:@"xScYgcHJ3Y2hwx7oh5x02NcCTwqBonnumTeRHThI" modelBundleURL: @"https://improve-v5-resources-test-models-117097735164.s3-us-west-2.amazonaws.com/models/mindful/mlmodel/improve-mlmodel-2020-5-11-0-11-47-8f23be6d-7fe7-427a-93e5-5cc14fa60133.tar.gz"];

    [[Improve instanceWithName:kTrainingInstance] initializeWithApiKey:@"xScYgcHJ3Y2hwx7oh5x02NcCTwqBonnumTeRHThI" modelBundleURL:@"https://improve-v5-resources-test-models-117097735164.s3-us-west-2.amazonaws.com/models/test/mlmodel/latest.tar.gz"];
    [Improve instanceWithName:kTrainingInstance].trackUrl = @"https://u0cxvugtmi.execute-api.us-west-2.amazonaws.com/test/track";
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
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Stupidly waiting for models to load"];
    NSLog(@"Waiting for models to load...");
    XCTestExpectation *onReadyExpectation = [[XCTestExpectation alloc] initWithDescription:@"Expects onReady block to be called"];
    [improve onReady:^{
        [onReadyExpectation fulfill];
    }];
    NSTimeInterval seconds = 30;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        // TODO: default model test
        //        NSDictionary *models = [[Improve instance] modelBundlesByName];
        //        NSLog(@"Finish waiting.\nLoaded models:\n%@", models);
        //        XCTAssertNotNil(models[@"default"]);

        /* Note: in order to test model with rank we need better test trials to
         allow predictions without noise. */
        //[self testRankWithModelName:@"model2"];

        [expectation fulfill];
    });

    [self waitForExpectations:@[expectation, onReadyExpectation] timeout:(seconds + 5)];
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

#pragma mark - Tests with training

// Helper for training data generators
- (void)printJSON:(id)jsonObject {
    NSData *json = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
    XCTAssertNotNil(json);
    NSString *string = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    XCTAssertNotNil(string);
    NSLog(@"%@", string);
}

/*
 It's not an actual test case. Creates random training data
 including namespace, variants and rewards.
 {
 namespace: "",
 variantsToRewardsMap: {
 "variant1": 1.004,
 "variant2": 99.2,
 ...
 }
 }

 You can paste this JSON to variantsTraining.json file which is included in the test target
 bundle, and required for `-testVariantsTrainingChoosing` test case.
 */
/*- (void)testGenerateTrainingVariants {
    const NSInteger variantsCount = 10;

    // Generate
    NSString *randomNamespace = [TestUtils randomStringWithMinLength:4
                                                           maxLength:100];
    NSMutableDictionary *variantsToRewards = [NSMutableDictionary dictionaryWithCapacity:variantsCount];
    for (int i = 0; i < variantsCount; i++) {
        NSString *variant = [TestUtils randomStringWithMinLength:1 maxLength:500];
        double reward = 100 * drand48();
        variantsToRewards[variant] = @(reward);
    }

    // Compose JSON object
    NSDictionary *output = @{
        @"namespace": randomNamespace,
        @"variantsToRewardsMap": variantsToRewards
    };

    [self printJSON:output];
}*/

/**
 Returns a dictionary from variantsTraining.json.
 Dictionary contains "namespace" and "variantsToRewardsMap".
 */
- (NSDictionary *)variantsTrainingChoosingJSON {
    NSURL *url = [[TestUtils bundle] URLForResource:@"variantsTraining" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertNotNil(json);
    return json;
}

/**
 Performs training with a random variants and rewards, no context. Each variant has it's own predifined reward.
 */
- (void)testVariantsTraining {
    // Get data
    NSDictionary *json = [self variantsTrainingChoosingJSON];
    NSString *namespaceString = json[@"namespace"];
    NSDictionary *variantsToRewards = json[@"variantsToRewardsMap"];
    NSArray *variants = [variantsToRewards allKeys];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"onReady"];

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    [impr onReady:^{
        // Train
        for (int iteration = 0; iteration < 1000; iteration++) {
            NSString *variant = [impr choose:namespaceString variants:variants];
            [impr trackDecision:namespaceString variant:variant];
            [impr trackReward:namespaceString value:variantsToRewards[variant]];
        }

        NSLog(@"Waiting for all track HTTP requests to complete");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [expectation fulfill];
        });
    }];
    [self waitForExpectations:@[expectation] timeout:60.0];
}

/**
 Tests the trained model with variants and no context. Test passed if the best variant (one with the highest reward)
 is chosen most of time, defined by the `desiredSuccess` constant.
 */
- (void)testVariantsChoosing {
    const int iterations = 1000;
    const float desiredSuccess = 0.95;

    NSDictionary *json = [self variantsTrainingChoosingJSON];
    NSDictionary *variantsToRewards = json[@"variantsToRewardsMap"];
    NSString *correctVariant = nil;
    double bestReward = -1;
    for (NSString *variant in variantsToRewards) {
        double reward = [variantsToRewards[variant] doubleValue];
        if (reward > bestReward) {
            correctVariant = variant;
            bestReward = reward;
        }
    }
    NSString *namespaceString = json[@"namespace"];
    NSArray *variants = [variantsToRewards allKeys];

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    int successCount = 0;
    for (int iteration = 0; iteration < iterations; iteration++) {
        NSString *chosenVariant = [impr choose:namespaceString variants:variants];
        successCount += [chosenVariant isEqualToString:correctVariant] ? 1 : 0;
    }

    float successRate = (float)successCount / iterations;
    NSLog(@"success: %f", successRate);
    XCTAssert(successRate >= desiredSuccess);
}

/*
 It's not an actual test case. Creates random training data
 including namespace, variants and context {bestKey: bestVariant}.
 {
 namespace: "",
 variants: [],
 bestKey: "",
 bestVariant: ""
 }

 You can paste this JSON to variantsContextTraining.json file which is included in
 the test target bundle, and required for `-testVariantsAndContextTraining` test case.
 */
/*- (void)testGenerateVariantsForContext {
    const NSInteger variantsCount = 5;

    // Generate
    NSString *randomNamespace = [TestUtils randomStringWithMinLength:3
                                                           maxLength:150];
    NSMutableArray *variants = [NSMutableArray arrayWithCapacity:variantsCount];
    for (int i = 0; i < variantsCount; i++) {
        [variants addObject:[TestUtils randomStringWithMinLength:4
                                                       maxLength:500]];
    }
    NSString *bestKey = [TestUtils randomStringWithMinLength:4 maxLength:20];
    NSString *bestVariant = [variants randomObject];

    // Compose JSON object
    NSDictionary *output = @{
        @"namespace": randomNamespace,
        @"variants": variants,
        @"bestKey": bestKey,
        @"bestVariant": bestVariant
    };

    [self printJSON:output];
}*/

/**

 */
- (NSDictionary *)variantsForContextTrainingChoosingJSON {
    NSURL *url = [[TestUtils bundle] URLForResource:@"variantsForContextTraining" withExtension:@"json"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    XCTAssertNotNil(json);
    return json;
}

/**

 */
- (void)testVariantsAndContextTraining {
    // Get data
    NSDictionary *json = [self variantsForContextTrainingChoosingJSON];
    NSString *namespaceString = json[@"namespace"];
    NSArray *variants = json[@"variants"];
    NSString *bestVariant = json[@"bestVariant"];
    NSDictionary *context = @{json[@"bestKey"]: bestVariant};

    // Train
    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    for (int iteration = 0; iteration < 1000; iteration++) {
        NSString *variant = [impr choose:namespaceString
                                variants:variants
                                 context:context];
        [impr trackDecision:namespaceString variant:variant context:context];

        double reward = [variant isEqualToString:bestVariant] ? 1.0 : 0.0;
        [impr trackReward:namespaceString value:@(reward)];
    }
}

/**

 */
- (void)testVariantsAndContextChoosing {
    const int iterations = 1000;
    const float desiredSuccess = 0.95;

    NSDictionary *json = [self variantsForContextTrainingChoosingJSON];
    NSString *namespaceString = json[@"namespace"];
    NSArray *variants = json[@"variants"];
    NSString *bestVariant = json[@"bestVariant"];
    NSDictionary *context = @{json[@"bestKey"]: bestVariant};
    
    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    int successCount = 0;
    for (int iteration = 0; iteration < iterations; iteration++) {
        NSString *chosenVariant = [impr choose:namespaceString
                                      variants:variants
                                       context:context];
        successCount += [chosenVariant isEqualToString:bestVariant] ? 1 : 0;
    }

    float successRate = (float)successCount / iterations;
    NSLog(@"success: %f", successRate);
    XCTAssert(successRate >= desiredSuccess);
}

@end
