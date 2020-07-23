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


NSString *const kTrainingInstance = @"training_tests";


@interface TrainingTestHelper : NSObject

+ (instancetype)shared;

/// Data from MultitypeSortTestTrainingData.json
@property(nonatomic, strong) NSDictionary *sortTestTrainingData;

/// Data from MultitypeContextTestTrainingData.json
@property(nonatomic, strong) NSArray *contextTestTrainingData;

- (void)configureTrainingInstance:(Improve *)instance;

- (void)printJSON:(id)jsonObject;

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
    NSDictionary *json = self.helper.sortTestTrainingData;
    NSString *namespaceString = json[@"namespace"];
    NSArray *trials = json[@"trials"];
    NSArray *rewards = json[@"rewards"];
    NSDictionary *context = json[@"context"];
    NSDictionary *trialsToRewardsMap = [NSDictionary dictionaryWithObjects:rewards forKeys:trials];

    XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for all track HTTP requests to complete"];

    Improve *impr = [Improve instanceWithName:kTrainingInstance];
    const NSTimeInterval waitTime = 300.0;
    // Comment-out onReady block to run initial trainig when there is no model
    [impr onReady:^{
        // Train
        for (int iteration = 0; iteration < 1000; iteration++) {
            NSString *variant = [impr choose:namespaceString variants:trials context:context];
            NSString *rewardKey = [self randomRewardKey];
            [impr trackDecision:namespaceString variant:variant context:context rewardKey:rewardKey];
            [impr addReward:trialsToRewardsMap[variant] forKey:rewardKey];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [expectation fulfill];
        });
    }];

    [self waitForExpectations:@[expectation] timeout:waitTime + 0.2];
}

/**
 Perfroms training with variants and context. Train model to choose the variant listed in the context.
 */
- (void)testVariantsAndContextTraining {
    NSArray *json = self.helper.contextTestTrainingData;
    // Separate test for each type
    NSMutableArray *expectations = [NSMutableArray new];
    for (NSDictionary *test in json)
    {
        NSString *namespaceString = test[@"namespace"];
        NSArray *variants = test[@"variants"];
        NSString *bestVariant = test[@"bestVariant"];
        NSDictionary *context = @{test[@"bestVariantKey"]: bestVariant};

        // Train
        Improve *impr = [Improve instanceWithName:kTrainingInstance];
        // Comment-out onReady block to run initial trainig when there is no model
        //[impr onReady:^{
            for (int iteration = 0; iteration < 1000; iteration++) {
                NSString *rewardKey = [self randomRewardKey];
                NSString *variant = [impr choose:namespaceString
                                        variants:variants
                                         context:context];
                [impr trackDecision:namespaceString
                            variant:variant context:context
                          rewardKey:rewardKey];

                double reward = [variant isEqualToString:bestVariant] ? 1.0 : 0.0;
                [impr addReward:@(reward) forKey:rewardKey];
            }

            XCTestExpectation *expectation = [[XCTestExpectation alloc] initWithDescription:@"Waiting for all track HTTP requests to complete"];
        [expectations addObject: expectation];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [expectation fulfill];
            });
        //}];
    }
    [self waitForExpectations:expectations timeout:20.0];
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

@end
