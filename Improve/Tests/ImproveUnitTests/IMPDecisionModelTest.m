//
//  DecisionModelTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/22/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionTracker.h"
#import "IMPDecisionModel.h"
#import "IMPDecision.h"
#import "IMPUtils.h"
#import "TestUtils.h"

extern NSString * const kRemoteModelURL;

@interface IMPDecisionModel ()

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)generateDescendingGaussians:(NSUInteger)count;

@end

@interface TestGivensProvider : GivensProvider

@end

@implementation TestGivensProvider

@end

@interface IMPDecisionModelTest : XCTestCase

@property (strong, nonatomic) NSArray *urlList;

@property (strong, nonatomic) NSURL *modelURL;

@property (strong, nonatomic) NSURL *bundledModelURL;

@end

@interface ModelDictionary ()

- (NSUInteger)count;

- (void)clear;

@end

@implementation IMPDecisionModelTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"%@", [[TestUtils bundle] bundlePath]);
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSURL *)modelURL {
    if(_modelURL == nil) {
        _modelURL = [NSURL URLWithString:kRemoteModelURL];
    }
    return _modelURL;
}

- (NSURL *)bundledModelURL {
    if(_bundledModelURL == nil) {
        _bundledModelURL = [[TestUtils bundle] URLForResource:@"TestModel"
                                                withExtension:@"mlmodelc"];
    }
    return _bundledModelURL;
}

- (void)testInit {
    NSString *modelName = @"hello";
    
    IMPDecisionModel *decisionModel_0 = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertEqualObjects(decisionModel_0.modelName, @"hello");
    XCTAssertNil(decisionModel_0.trackURL);
    
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
    
    IMPDecisionModel *decisionModel_1 = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertNotNil(decisionModel_1.trackURL);
    XCTAssertEqual(IMPDecisionModel.defaultTrackURL, decisionModel_1.trackURL);
}

// The modelName set before loading the model has higher priority than
// the modelName specified in the model file.
- (void)testModelName {
    NSString *modelName = @"hello";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSURL *url = [[TestUtils bundle] URLForResource:@"TestModel"
                                      withExtension:@"mlmodelc"];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [decisionModel loadAsync:url completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
        XCTAssertEqualObjects(modelName, decisionModel.modelName);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:3];
}

// modelName can be nil
- (void)testModelName_Nil {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:nil];
    XCTAssertNil(decisionModel.modelName);
    
    [decisionModel load:self.modelURL error:nil];
    NSLog(@"modelName = [%@]", decisionModel.modelName);
    XCTAssertTrue([decisionModel.modelName length] > 0);
    
}

// modelName length must be in range [1, 64]
- (void)testModelName_Empty {
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@""];
        NSLog(@"modelName = [%@]", decisionModel.modelName);
    } @catch(id exception) {
        // An exception is expected here.
        NSLog(@"modelName can't be empty.");
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

// modelName length must be in range [1, 64]
- (void)testModelName_Length_5 {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    NSLog(@"modelName = [%@]", decisionModel.modelName);
    XCTAssertEqualObjects(@"hello", decisionModel.modelName);
}

// modelName length must be in range [1, 64]
- (void)testModelName_Length_64 {
    NSString *modelName = @"";
    for(int i = 0; i < 64; ++i) {
        modelName = [modelName stringByAppendingString:@"0"];
    }
    XCTAssertEqual(64, modelName.length);
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSLog(@"modelName = [%@]", decisionModel.modelName);
    XCTAssertEqualObjects(modelName, decisionModel.modelName);
}

// modelName length must be in range [1, 64]
- (void)testModelName_Length_65 {
    NSString *modelName = @"";
    for(int i = 0; i < 65; ++i) {
        modelName = [modelName stringByAppendingString:@"0"];
    }
    XCTAssertEqual(65, modelName.length);
    
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
        NSLog(@"modelName = [%@]", decisionModel.modelName);
    } @catch(id exception) {
        // An exception is expected here
        NSLog(@"length of modelName can't exceed 64");
        return ;
    }
    
    XCTFail("An exception should have been thrown, we should never reach here");
}

- (void)testModelName_valid_characters {
    NSArray *modelNames = @[
        @"a",
        @"a_",
        @"a.",
        @"a-",
        @"a1",
        @"3Abb"
    ];
    
    for(int i = 0; i < [modelNames count]; ++i) {
        NSString *modelName = modelNames[i];
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
        XCTAssertEqual(modelName, decisionModel.modelName);
    }
    
}

- (void)testModelName_invalid_characters {
    NSArray *modelNames = @[
        @"_a",
        @"a+",
        @"a\\"
    ];
    
    for(int i = 0; i < [modelNames count]; ++i) {
        @try {
            NSString *modelName = modelNames[i];
            IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
            XCTAssertEqual(modelName, decisionModel.modelName);
        } @catch(id exception) {
            NSLog(@"case: %@, exception: %@", modelNames[i], exception);
            continue ;
        }
        NSLog(@"failed: %@", modelNames[i]);
        XCTFail(@"An exception should have been throw, we should never reach here.");
    }
}

- (void)testModelInstances {
    [IMPDecisionModel.instances clear];
    
    NSString *modelName = @"hello";
    // Create and cache the model if not exist
    XCTAssertEqual(0, [IMPDecisionModel.instances count]);
    IMPDecisionModel *decisionModel = IMPDecisionModel.instances[modelName];
    XCTAssertEqual(1, [IMPDecisionModel.instances count]);
    XCTAssertNotNil(decisionModel);
    XCTAssertEqual(decisionModel, IMPDecisionModel.instances[modelName]);
    
    IMPDecisionModel.instances[modelName] = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSLog(@"modelName: %@", IMPDecisionModel.instances[modelName].modelName);
    XCTAssertEqualObjects(modelName, IMPDecisionModel.instances[modelName].modelName);
    
    // Same object
    XCTAssertEqual(IMPDecisionModel.instances[modelName], IMPDecisionModel.instances[modelName]);
    
    // Overwrite existing model
    XCTAssertEqual(1, [IMPDecisionModel.instances count]);
    IMPDecisionModel *oldModel = IMPDecisionModel.instances[modelName];
    IMPDecisionModel.instances[modelName] = [[IMPDecisionModel alloc] initWithModelName:modelName];
    IMPDecisionModel *newModel = IMPDecisionModel.instances[modelName];
    // oldModel and newModel point to different objects
    XCTAssertNotEqual(oldModel, newModel);
    XCTAssertEqual(1, [IMPDecisionModel.instances count]);
    
    // set as nil to remove the existing model
    XCTAssertEqual(1, [IMPDecisionModel.instances count]);
    IMPDecisionModel.instances[modelName] = nil;
    XCTAssertEqual(0, [IMPDecisionModel.instances count]);
}

// modelName and the key must be equal
- (void)testModelInstances_Invalid {
    @try {
        IMPDecisionModel.instances[@"aaa"] = [[IMPDecisionModel alloc] initWithModelName:@"bbb"];
    } @catch(id exception) {
        return ;
    }
    XCTFail(@"An exception should have been thrown. We should never reach here");
}

- (void)testGivensProvider {
    NSString *modelName = @"hello";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertNotNil(decisionModel.givensProvider);
    XCTAssertEqual(decisionModel.givensProvider, IMPDecisionModel.defaultGivensProvider);
    
    decisionModel.givensProvider = [[TestGivensProvider alloc] init];
    XCTAssertNotNil(decisionModel.givensProvider);
    XCTAssertNotEqual(decisionModel.givensProvider, IMPDecisionModel.defaultGivensProvider);
}

- (void)testLoadLocalModelFile {
    NSError *error;
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"TestModel"
                         withExtension:@"dat"];
    NSLog(@"model url: %@", modelURL);
    NSString *modelName = @"greetings";
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [model load:modelURL error:&error];
    XCTAssertNil(error);
}

- (void)testLoadAsync{
    for(NSURL *url in self.urlList){
        XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@""];
        [decisionModel loadAsync:url completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
            if(error){
                NSLog(@"loadAsync error: %@", error);
            }
            XCTAssert([NSThread isMainThread]);
            XCTAssertNotNil(compiledModel);
            XCTAssertTrue([compiledModel.modelName length] > 0);
            [ex fulfill];
        }];
        [self waitForExpectations:@[ex] timeout:300];
    }
}

- (void)testLoadSync {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    NSError *err;
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertNotNil([decisionModel load:self.bundledModelURL error:&err]);
    XCTAssertNil(err);
    XCTAssertTrue([decisionModel.modelName length] > 0);
}

- (void)testLoadSyncToFail {
    NSError *err;
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.101/not/exist/TestModel.mlmodel3.gz"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:url error:&err]);
    XCTAssertNotNil(err);
    NSLog(@"loadToFail, error = %@", err);
}

- (void)testLoadSyncToFail_Nil_Error {
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.101/not/exist/TestModel.mlmodel3.gz"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:url error:nil]);
}

- (void)testLoadSyncToFailWithInvalidModelFile {
    NSError *err;
    // The model exists, but is not valid
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"InvalidModel"
                         withExtension:@"dat"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:modelURL error:&err]);
    XCTAssertNotNil(err);
    NSLog(@"load error: %@", err);
}

- (void)testLoadSyncFromNonMainThread{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        XCTAssertFalse([NSThread isMainThread]);
        NSError *err;
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
        XCTAssertNotNil([decisionModel load:self.bundledModelURL error:&err]);
        XCTAssertNil(err);
        XCTAssertTrue([decisionModel.modelName length] > 0);
        NSLog(@"modelName: %@", decisionModel.modelName);
        [ex fulfill];
    });
    [self waitForExpectations:@[ex] timeout:30];
}

- (void)testDescendingGaussians {
    int n = 40000;
    double total = 0.0;
    
    NSArray *array = [IMPDecisionModel generateDescendingGaussians:n];
    XCTAssertEqual(array.count, n);
    
    for(int i = 0; i < n; ++i) {
        total += [[array objectAtIndex:i] doubleValue];
    }
    
    NSLog(@"median = %f, average = %f", [[array objectAtIndex:n/2] doubleValue], total / n);
    XCTAssertLessThan(ABS([[array objectAtIndex:n/2] doubleValue]), 0.05);
    
    // Test that it it descending
    for(int i = 0; i < n-1; ++i) {
        XCTAssertGreaterThan([array[i] doubleValue], [array[i+1] doubleValue]);
    }
}

- (void)testScoreWithNilVariants {
    NSArray *variants = nil;
    NSDictionary *context = @{@"language": @"cowboy"};
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    NSArray *scores = [model score:variants given:context];
    XCTAssertNotNil(scores);
    XCTAssertEqual([scores count], 0);
}

- (void)testScoreWithEmptyVariants {
    NSArray *variants = @[];
    NSDictionary *context = @{@"language": @"cowboy"};
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    NSArray *scores = [model score:variants given:context];
    XCTAssertNotNil(scores);
    XCTAssertEqual([scores count], 0);
}

- (void)testScoreWithoutLoadingModel {
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < 100; i++) {
        [variants addObject:@(i)];
    }
    
    NSDictionary *context = @{@"language": @"cowboy"};
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    NSArray<NSNumber *> *scores = [model score:variants given:context];
    XCTAssertNotNil(scores);
    XCTAssertEqual([scores count], [variants count]);
    
    // assert that scores is in descending order
    NSInteger size = [variants count];
    for(int i = 0; i < size-1; ++i) {
        NSLog(@"score[%d] = %lf", i, [scores[i] doubleValue]);
        XCTAssertGreaterThan([scores[i] doubleValue], [scores[i+1] doubleValue]);
    }
}

- (void)testChooseFrom {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *context = @{@"language": @"cowboy"};
    
    NSURL *modelURL = [NSURL URLWithString:kRemoteModelURL];
    
    NSError *err;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel load:modelURL error:&err];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(err);
    NSString *greeting = [[[decisionModel given:context] chooseFrom:variants] get];
    IMPLog("url=%@, greeting=%@", modelURL, greeting);
    XCTAssertNotNil(greeting);
}

extern NSString * const kTrackerURL;

// variants are json encodable
- (void)testChooseFromValidVariants {
    // variant must be one of type NSArray, NSDictionary, NSString, NSNumber, Boolean, or NSNull
    NSArray *variants = @[@[@"hello", @"hi"],
                          @{@"color":@"#ff0000", @"flag":@(YES), @"font":[NSNull null]},
                          @"Hi World",
                          @(3),
                          @(3.0),
                          @(YES),
                          [NSNull null]
    ];
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel load:self.modelURL error:nil];
    [[decisionModel chooseFrom:variants] get];
}

// variants are not json encodable
- (void)testChooseFromInvalidVariants {
    NSURL *urlVariant = [NSURL URLWithString:@"https://hello.com"];
    NSDate *dateVariant = [NSDate date];
    
    NSArray *variants = @[urlVariant, dateVariant];
    
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel load:self.modelURL error:&error];
    XCTAssertNil(error);
    @try {
        [[decisionModel chooseFrom:variants] get];
    } @catch (NSException *e){
        NSLog(@"%@", e);
        return ;
    }
    XCTFail(@"We should never reach here. An exception should have been thrown.");
}

- (void)testRank{
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    
    // shuffle
    srand((unsigned int)time(0));
    for(NSUInteger i = 0; i < variants.count*10; ++i){
        NSUInteger m = rand() % variants.count;
        NSUInteger n = rand() % variants.count;
        [variants exchangeObjectAtIndex:m withObjectAtIndex:n];
        [scores exchangeObjectAtIndex:m withObjectAtIndex:n];
    }
    for(int i = 0; i < variants.count; ++i){
        NSLog(@"variant before sorting: %d", variants[i].intValue);
    }
    
    NSLog(@"\n");
    NSArray<NSNumber *> *result = [IMPDecisionModel rank:variants withScores:scores];
    
    for(NSUInteger i = 0; i+1 < variants.count; ++i){
        XCTAssert(result[i].unsignedIntValue > result[i+1].unsignedIntValue);
    }
    
    for(int i = 0; i < variants.count; ++i){
        NSLog(@"variant after sorting: %d", result[i].intValue);
    }
}

- (void)testRank_larger_variants_size {
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    variants[size] = [NSNumber numberWithInt:size];
    
    @try {
        NSArray<NSNumber *> *result = [IMPDecisionModel rank:variants withScores:scores];
        NSLog(@"ranked size = %lu", result.count);
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should not have reached here.");
}

- (void)testRank_larger_scores_size {
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    scores[size] = [NSNumber numberWithDouble:size/100000.0];
    
    @try {
        NSArray<NSNumber *> *result = [IMPDecisionModel rank:variants withScores:scores];
        NSLog(@"ranked size = %lu", result.count);
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should not have reached here.");
}

- (void)testTopScoringVariant{
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    
    // shuffle
    srand((unsigned int)time(0));
    for(NSUInteger i = 0; i < variants.count; ++i){
        NSUInteger m = rand() % variants.count;
        NSUInteger n = rand() % variants.count;
        [variants exchangeObjectAtIndex:m withObjectAtIndex:n];
        [scores exchangeObjectAtIndex:m withObjectAtIndex:n];
    }
    
    NSArray<NSNumber *> *rankedResult = [IMPDecisionModel rank:variants withScores:scores];
    
    for(int i = 0; i < variants.count; ++i){
        NSLog(@"variants: %@", variants[i]);
    }
    id topScoringVariant = [IMPDecisionModel topScoringVariant:variants withScores:scores];
    NSLog(@"topScoringVariant: %@", topScoringVariant);
    XCTAssertEqual(rankedResult[0], topScoringVariant);
    
    // in case of tie, the lowest index wins
    [variants addObject:@10.1];
    [variants addObject:@10.2];
    [variants addObject:@10.3];
    
    [scores addObject:@10];
    [scores addObject:@10];
    [scores addObject:@10];
    
    topScoringVariant = [IMPDecisionModel topScoringVariant:variants withScores:scores];
    NSLog(@"topScoringVariant: %@", topScoringVariant);
    XCTAssertEqual([topScoringVariant doubleValue], 10.1);
}

// variants.count > scores.count, an exception should be thrown
- (void)testTopScoringVariant_larger_variant_size {
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    variants[size] = [NSNumber numberWithInt:size];
    
    @try {
        [IMPDecisionModel topScoringVariant:variants withScores:scores];
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should not have reached here.");
}

// scores.count > variants.count, an exception should be thrown
- (void)testTopScoringVariant_larger_scores_size {
    NSMutableArray<NSNumber *> *variants = [[NSMutableArray alloc] init];
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    int size = 10;
    
    for(NSUInteger i = 0; i < size; ++i){
        variants[i] = [NSNumber numberWithInteger:i];
        scores[i] = [NSNumber numberWithDouble:i/100000.0];
    }
    scores[size] = [NSNumber numberWithDouble:size/100000.0];
    
    @try {
        [IMPDecisionModel topScoringVariant:variants withScores:scores];
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should not have reached here.");
}

- (void)testDumpScore_11 {
    int size = 11;
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    for(int i = 0; i < size; ++i) {
        [scores addObject:@((double)arc4random() / UINT32_MAX)];
    }
    
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < size; ++i) {
        [variants addObject:[NSString stringWithFormat:@"Hello-%d", i]];
    }
    
    for(int i = 0; i < size; ++i) {
        NSLog(@"#%d, score:%lf variant:%@", i, [scores[i] doubleValue], variants[i]);
    }
    
    [IMPUtils dumpScores:scores andVariants:variants];
    
    for(int i = 0; i < size; ++i) {
        NSLog(@"#%d, score:%lf variant:%@", i, [scores[i] doubleValue], variants[i]);
    }
}

- (void)testDumpScore_21 {
    int size = 21;
    NSMutableArray *scores = [[NSMutableArray alloc] init];
    for(int i = 0; i < size; ++i) {
        [scores addObject:@((double)arc4random() / UINT32_MAX)];
    }
    
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < size; ++i) {
        NSDictionary *variant = @{@"greeting":@"hi", @"index":@11};
        [variants addObject:variant];
    }
    
    [IMPUtils dumpScores:scores andVariants:variants];
}

@end
