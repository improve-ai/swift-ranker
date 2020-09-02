//
//  ImproveTrainingTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 7/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Improve.h"
#import "IMPModelBundle.h"
#import "TestUtils.h"
#import "NSArray+Random.h"


NSString *const kTrainingInstance = @"training_tests";

NSString *const kHappySundayWeekdayContextKey = @"weekday";

NSString *const kHappySundayObjectContextKey = @"object";

@interface TrainingTestHelper : NSObject

+ (instancetype)shared;

/// Data from MultitypeSortTestTrainingData.json
@property(nonatomic, strong) NSDictionary *sortTestTrainingData;

/// Data from MultitypeContextTestTrainingData.json
@property(nonatomic, strong) NSArray *contextTestTrainingData;

/**
 {
     @"namespace": ...,
     @"variants": @[
         @"Have a Great Day!",
         @"Have an Okay Day.",
         @"Happy Sunday",
         @"Happy Monday",
         @"Happy Tuesday",
         @"Happy Wednesday",
         @"Happy Thursday",
         @"Happy Friday",
         @"Happy Saturday",
         @"Happy \"string\"",
         @"Happy []",
         @"Happy {}",
         @"Happy null"
     ]
 }
 */
@property(readonly, strong) NSDictionary *happySundayTestData;

- (void)configureTrainingInstance:(Improve *)instance;

- (void)printJSON:(id)jsonObject;

- (NSDictionary *)randomHappySundayContext;

- (double)rewardForHappySundayVariant:(NSString *)variant context:(NSDictionary *)context;

@end

#pragma mark - Train

@interface ImproveTrainingTest : XCTestCase
@property (nonatomic, strong) TrainingTestHelper *helper;
@end

@implementation ImproveTrainingTest

- (void)setUp {
    self.helper = [TrainingTestHelper shared];
    XCTAssertNotNil(self.helper);
    XCTAssertNotNil(self.helper.sortTestTrainingData);
    XCTAssertNotNil(self.helper.contextTestTrainingData);

    Improve *trainingInstance = [Improve instanceWithName:kTrainingInstance];
    [self.helper configureTrainingInstance:trainingInstance];
}

- (NSString *)randomRewardKey {
    return [TestUtils randomStringWithMinLength:8 maxLength:10];
}

/**
 Performs training with a random variants and rewards, no context. Each variant has it's own predifined reward.
 */
- (void)testVariantsTraining {
    const int iterationsCount = 1000;
    NSDictionary *json = self.helper.sortTestTrainingData;
    NSString *namespaceString = json[@"namespace"];
    NSArray *trials = json[@"trials"];
    NSArray *rewards = json[@"rewards"];
    NSDictionary *context = json[@"context"];
    NSDictionary *trialsToRewardsMap = [NSDictionary dictionaryWithObjects:rewards forKeys:trials];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for all track HTTP requests to complete"];
    expectation.expectedFulfillmentCount = iterationsCount;

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    // Comment-out onReady block to run initial trainig when there is no model
    [impr onReady:^{
        // Train
        for (int iteration = 0; iteration < iterationsCount; iteration++) {
            NSString *variant = [impr choose:namespaceString variants:trials context:context];
            NSString *rewardKey = [self randomRewardKey];
            // Add semaphore so requests will be sent one by one
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [impr trackDecision:namespaceString
                        variant:variant
                        context:context
                      rewardKey:rewardKey
                     completion:^(NSError * _Nullable error) {
                [impr addReward:trialsToRewardsMap[variant]
                         forKey:rewardKey
                     completion:^(NSError * _Nullable error) {
                    [expectation fulfill];
                    dispatch_semaphore_signal(semaphore);
                }];
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    }];

    [self waitForExpectations:@[expectation] timeout:(0.5 * iterationsCount)];
}

/**
 Perfroms training with variants and context. Train model to choose the variant listed in the context.
 */
- (void)testVariantsAndContextTraining {
    const int iterationsCount = 1000;
    NSArray *json = self.helper.contextTestTrainingData;
    // Separate test for each type
    NSMutableArray *expectations = [NSMutableArray new];
    for (NSDictionary *test in json)
    {
        NSString *namespaceString = test[@"namespace"];
        NSArray *variants = test[@"variants"];
        id bestVariant = test[@"bestVariant"];
        NSDictionary *context = @{test[@"bestVariantKey"]: bestVariant};

        // Train
        Improve *impr = [Improve instanceWithName:kTrainingInstance];
        XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for all track HTTP requests to complete"];
        expectation.expectedFulfillmentCount = iterationsCount;
        [expectations addObject:expectation];
        // Comment-out onReady block to run initial trainig when there is no model
        //[impr onReady:^{
            for (int iteration = 0; iteration < iterationsCount; iteration++) {
                NSString *rewardKey = [self randomRewardKey];
                NSString *variant = [impr choose:namespaceString
                                        variants:variants
                                         context:context];
                double reward = [variant isEqual:bestVariant] ? 1.0 : 0.0;

                // Add semaphore so requests will be sent one by one
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                [impr trackDecision:namespaceString
                            variant:variant
                            context:context
                          rewardKey:rewardKey
                         completion:^(NSError * _Nullable error) {
                    [impr addReward:@(reward)
                             forKey:rewardKey
                         completion:^(NSError * _Nullable error) {
                        [expectation fulfill];
                        dispatch_semaphore_signal(semaphore);
                    }];
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
        //}];
    }
    [self waitForExpectations:expectations timeout:(5.0 * iterationsCount)];
}

- (void)testHappySundayTraining {
    const int trainIterations = 5000;
    NSString *namespace = self.helper.happySundayTestData[@"namespace"];
    NSArray *variants = self.helper.happySundayTestData[@"variants"];

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for all track HTTP requests to complete"];
    expectation.expectedFulfillmentCount = trainIterations;
    [impr onReady:^{
        for (int iteration = 0; iteration < trainIterations; iteration++) {
            NSLog(@"### Iteration: %d", iteration);
            NSString *rewardKey = [self randomRewardKey];
            NSDictionary *context = [self.helper randomHappySundayContext];
            NSString *variant = [impr choose:namespace
                                    variants:variants
                                     context:context];
            double reward = [self.helper rewardForHappySundayVariant:variant context:context];
            // Add semaphore so requests will be sent one by one
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [impr trackDecision:namespace
                        variant:variant
                        context:context
                      rewardKey:rewardKey
                     completion:^(NSError *error) {
                [impr addReward:@(reward) forKey:rewardKey completion:^(NSError *error) {
                    [expectation fulfill];
                    dispatch_semaphore_signal(semaphore);
                }];
            }];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        }
    }];
    [self waitForExpectations:@[expectation] timeout:(5.0 * trainIterations)];
}

@end

#pragma mark - Check

@interface ImproveTrainingCheck : XCTestCase
@property (nonatomic, strong) TrainingTestHelper *helper;
@end

@implementation ImproveTrainingCheck

- (void)setUp {
    self.helper = [TrainingTestHelper shared];
    XCTAssertNotNil(self.helper);
    XCTAssertNotNil(self.helper.sortTestTrainingData);
    XCTAssertNotNil(self.helper.contextTestTrainingData);

    Improve *trainingInstance = [Improve instanceWithName:kTrainingInstance];
    [self.helper configureTrainingInstance:trainingInstance];
}

/**
 Perform test to check how well the model was trained with -[ImproveTrainingTest testVariantsTraining].
 This method will perfrom number of 'sort' iterations, sorting variants each time and checking if the order is correct.
 Then it will print out the success rate - ratio between correct sorts and total number of attempts.
 */
- (void)testVariantsSorting {
    const int iterations = 1000;
    const float desiredSuccess = 0.95;

    NSDictionary *json = self.helper.sortTestTrainingData;
    NSString *namespaceString = json[@"namespace"];
    NSArray *variants = json[@"trials"];
    NSDictionary *context = json[@"context"];

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    [impr onReady:^{
        int successCount = 0;
        for (int iteration = 0; iteration < iterations; iteration++) {
            NSArray *sortedVariants = [impr sort:namespaceString variants:variants context:context];
            successCount += [sortedVariants isEqualToArray:variants] ? 1 : 0;
        }

        float successRate = (float)successCount / iterations;
        NSLog(@"success: %f", successRate);
        XCTAssert(successRate >= desiredSuccess);
    }];
}

/**
 Perform test to check how well the model was trained with -[ImproveTrainingTest testVariantsAndContextTraining].
 For each type in the data array this method will perform choosing with {bestKey: bestVariant} context. If the best variant
 is chosen - it will increase the success count. Then prints out the success rate for the current type - ratio between correct choses and total number of attempts. Finally prints accumulated success count.
 */
- (void)testVariantsAndContextChoosing {
    const int iterations = 500;
    const float desiredSuccess = 0.95;

    NSArray *json = self.helper.contextTestTrainingData;
    Improve *impr = [Improve instanceWithName:kTrainingInstance];

    [impr onReady:^{
        int accumulatedSuccessCount = 0;
        int accumulatedIterations = 0;

        for (NSDictionary *test in json)
        {
            NSString *namespaceString = test[@"namespace"];
            NSArray *variants = test[@"variants"];
            NSString *bestVariant = test[@"bestVariant"];
            NSDictionary *context = @{test[@"bestVariantKey"]: bestVariant};

            int successCount = 0;
            accumulatedIterations += iterations;
            for (int iteration = 0; iteration < iterations; iteration++) {
                NSString *chosenVariant = [impr choose:namespaceString
                                              variants:variants
                                               context:context];
                if ([chosenVariant isEqualToString:bestVariant]) {
                    successCount++;
                    accumulatedSuccessCount++;
                }
            }

            float successRate = (float)successCount / iterations;
            NSLog(@"%@ success: %f", namespaceString, successRate);
            XCTAssert(successRate >= desiredSuccess);
        }

        float accumulatedSuccess = (float)accumulatedSuccessCount / accumulatedIterations;
        NSLog(@"accumulated success: %f", accumulatedSuccess);
        XCTAssert(accumulatedSuccess >= desiredSuccess);
    }];
}

- (void)testHappySunday {
    const int testIterations = 1000;
    // The test will be considered to pass when the cumulative reward is > then this value
    const double targetCummulativeReward = (double)testIterations * 0.9;
    NSString *namespace = self.helper.happySundayTestData[@"namespace"];
    NSArray *variants = self.helper.happySundayTestData[@"variants"];

    // Generate random cumulative reward in order to compare it to the actual reward
    double randomCumulativeReward = 0;
    for (int i = 0; i < testIterations; i++) {
        NSDictionary *context = [self.helper randomHappySundayContext];
        NSString *variant = [variants randomObject];
        double reward = [self.helper rewardForHappySundayVariant:variant context:context];
        randomCumulativeReward += reward;
    }
    NSLog(@"random cumulative reward: %g (of %g)", randomCumulativeReward, targetCummulativeReward);

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model to load"];
    [impr onReady:^{
        double cummulativeReward = 0;
        for (int iteration = 0; iteration < testIterations; iteration++) {
            NSDictionary *context = [self.helper randomHappySundayContext];
            NSString *variant = [impr choose:namespace
                                    variants:variants
                                     context:context];
            double reward = [self.helper rewardForHappySundayVariant:variant context:context];
            NSLog(@"Happy Sunday test iteration\nvariant: %@\ncontext: %@\nreward: %g", variant, context, reward);
            cummulativeReward += reward;
        }
        NSLog(@"iterations: %d, cummulative reward: %g (of %g)", testIterations, cummulativeReward, targetCummulativeReward);
        XCTAssert(cummulativeReward > targetCummulativeReward);
        [expectation fulfill];
    }];
    [self waitForExpectations:@[expectation] timeout:60];
}

@end

#pragma mark - Helper

@implementation TrainingTestHelper

+ (instancetype)shared {
    static TrainingTestHelper *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSURL *url = [[TestUtils bundle] URLForResource:@"MultitypeSortTestTrainingData" withExtension:@"json"];
        NSData *data = [NSData dataWithContentsOfURL:url];
        _sortTestTrainingData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        url = [[TestUtils bundle] URLForResource:@"MultitypeContextTestTrainingData" withExtension:@"json"];
        data = [NSData dataWithContentsOfURL:url];
        _contextTestTrainingData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        _happySundayTestData = @{
            @"namespace": @"happy_sunday_test_2",
            @"variants": @[
                @"Have a Great Day!",
                @"Have an Okay Day.",
                @"Happy Sunday",
                @"Happy Monday",
                @"Happy Tuesday",
                @"Happy Wednesday",
                @"Happy Thursday",
                @"Happy Friday",
                @"Happy Saturday",
                @"Happy \"string\"",
                @"Happy []",
                @"Happy {}",
                @"Happy null"
            ]
        };
    }
    return self;
}

- (void)printJSON:(id)jsonObject {
    NSData *json = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted error:nil];
    NSString *string = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSLog(@"%@", string);
}

- (void)configureTrainingInstance:(Improve *)trainingInstance
{
    [trainingInstance initializeWithApiKey:@"xScYgcHJ3Y2hwx7oh5x02NcCTwqBonnumTeRHThI" modelBundleURL:@"https://improve-v5-resources-test-models-117097735164.s3-us-west-2.amazonaws.com/models/test/mlmodel/latest.tar.gz"];
    trainingInstance.trackUrl = @"https://u0cxvugtmi.execute-api.us-west-2.amazonaws.com/test/track";
    trainingInstance.maxModelsStaleAge = 10;
}

/**
 Reward for a variant for "Happy Sunday" test. See `happySundayTestData` for possible variants.
 @param variant One of predefined variants.
 @param context Contex containing day of week - NSNumber starting from Sunday (0) to Saturday (6). May also contain [], {}, NSNull, boolean or other test objects.
 */
- (double)rewardForHappySundayVariant:(NSString *)variant context:(NSDictionary *)context
{
    NSNumber *dayNumber = context[kHappySundayWeekdayContextKey];
    if (dayNumber) {
        int day = dayNumber.intValue;
        if ([variant isEqualToString:@"Have a Great Day!"]) {
            return 1.0;
        } else if ([variant isEqualToString:@"Have an Okay Day."]) {
            return 0.0;
        } else if (day == 0 && [variant isEqualToString:@"Happy Sunday"]) {
            return 2.0;
        } else if (day == 1 && [variant isEqualToString:@"Happy Monday"]) {
            return 2.0;
        } else if (day == 2 && [variant isEqualToString:@"Happy Tuesday"]) {
            return 2.0;
        } else if (day == 3 && [variant isEqualToString:@"Happy Wednesday"]) {
            return 2.0;
        } else if (day == 4 && [variant isEqualToString:@"Happy Thursday"]) {
            return 2.0;
        } else if (day == 5 && [variant isEqualToString:@"Happy Friday"]) {
            return 2.0;
        } else if (day == 6 && [variant isEqualToString:@"Happy Saturday"]) {
            return 2.0;
        }
    }

    id object = context[kHappySundayObjectContextKey];
    if (object) {
        if ([object isEqual:@"string"] && [variant isEqualToString:@"Happy \"string\""]) {
            return 2.0;
        } else if ([object isEqual:@[]] && [variant isEqualToString:@"Happy []"]) {
            return 2.0;
        } else if ([object isEqual:@{}] && [variant isEqualToString:@"Happy {}"]) {
            return 2.0;
        } else if ([object isEqual:[NSNull null]] && [variant isEqualToString:@"Happy null"]) {
            return 2.0;
        }
    }

    return -1.0;
}

/**
 Context may contain either a day value for "weekday" key or a special value for "object" key.
 Special values may include NSNull, [], {}, NSString etc.
 */
- (NSDictionary *)randomHappySundayContext {
    if (drand48() < 0.8)
    {
        int dayOfWeek = arc4random_uniform(6);
        return @{kHappySundayWeekdayContextKey: @(dayOfWeek)};
    }
    else
    {
        NSArray *objects = @[[NSNull null], @[], @{}, @"string"];
        return @{kHappySundayObjectContextKey: objects.randomObject};
    }
}

@end
