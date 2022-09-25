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
#import "IMPDecisionContext.h"
#import "IMPDecision.h"
#import "IMPUtils.h"
#import "TestUtils.h"
#import "IMPFeatureEncoder.h"
#import "IMPConstants.h"
#import "AppGivensProvider.h"

NSString * const kReasonVariantsNonEmpty = @"variants can't be nil or empty.";

extern NSString * const kRemoteModelURL;

extern NSString *const kTrackApiKey;

// Package private properties
@interface IMPDecision ()

@property (nonatomic, copy) NSArray *variants;

@property (nonatomic, copy) NSArray *rankedVariants;

@property(nonatomic, strong) NSArray *scores;

@property(nonatomic, strong) NSDictionary *givens;

@property (nonatomic, readonly) int tracked;

@end

@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

+ (nullable id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores;

+ (NSArray *)generateDescendingGaussians:(NSUInteger)count;

- (IMPFeatureEncoder *)featureEncoder;

- (BOOL)enableTieBreaker;

- (void)setEnableTieBreaker:(BOOL)enableTieBreaker;

- (BOOL)canParseVersion:(NSString *)versionString;

- (BOOL)isLoaded;

@end

@interface TestGivensProvider : IMPGivensProvider

@end

@implementation TestGivensProvider

@end

@interface IMPDecisionModelTest : XCTestCase

@property (strong, nonatomic) NSURL *modelURL;

@property (strong, nonatomic) NSURL *bundledModelURL;

@end

@interface IMPModelDictionary ()

- (NSUInteger)count;

- (void)clear;

@end

@interface IMPDecisionTracker ()

+ (nullable NSString *)lastDecisionIdOfModel:(NSString *)modelName;

@end

@implementation IMPDecisionModelTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"%@", [[TestUtils bundle] bundlePath]);
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
    IMPDecisionModel.defaultTrackApiKey = kTrackApiKey;
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

- (nullable IMPDecisionModel *)loadedModel {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    return [decisionModel load:[NSURL URLWithString:kRemoteModelURL] error:nil];
}

- (IMPDecisionModel *)unloadedModel {
    return [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
}

- (NSArray *)variants {
    return @[@"Hello World", @"Howdy World", @"Hi World"];
}

- (void)testInit {
    NSString *modelName = @"hello";
    
    IMPDecisionModel *decisionModel_0 = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertEqualObjects(decisionModel_0.modelName, modelName);
    XCTAssertNotNil(decisionModel_0.trackURL);
    XCTAssertNotNil(decisionModel_0.trackURL);
    XCTAssertNotNil(decisionModel_0.trackApiKey);
    
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
    
    IMPDecisionModel *decisionModel_1 = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertNotNil(decisionModel_1.trackURL);
    XCTAssertEqual(IMPDecisionModel.defaultTrackURL, decisionModel_1.trackURL);
}

- (void)testInit_nil_url_and_apikey {
    NSString *modelName = @"hello";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName trackURL:nil trackApiKey:nil];
    XCTAssertNil(decisionModel.tracker);
    XCTAssertNil(decisionModel.trackApiKey);
    XCTAssertNil(decisionModel.trackURL);
    
    decisionModel.trackURL = [NSURL URLWithString:kTrackerURL];
    IMPDecisionTracker *tracker = decisionModel.tracker;
    XCTAssertNotNil(tracker);
    XCTAssertNotNil(decisionModel.trackURL);
    XCTAssertNil(decisionModel.trackApiKey);
    
    decisionModel.trackApiKey = kTrackApiKey;
    XCTAssertEqual(tracker, decisionModel.tracker); // same object
    XCTAssertNotNil(decisionModel.tracker);
    XCTAssertNotNil(decisionModel.trackApiKey);
    XCTAssertEqualObjects(kTrackApiKey, decisionModel.trackApiKey);
}

- (void)testInit_mutable_modelName {
    NSMutableString *modelName = [[NSMutableString alloc] initWithString:@"hello"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    XCTAssertNotEqual(modelName, decisionModel.modelName); // not same object
    
    XCTAssertEqualObjects(@"hello", decisionModel.modelName);
    [modelName setString:@"world"];
    XCTAssertEqualObjects(@"hello", decisionModel.modelName);
}

- (void)testInit_mutable_trackApiKey {
    NSMutableString *trackApiKey = [[NSMutableString alloc] initWithString:@"hello"];
    NSURL *trackURL = [NSURL URLWithString:kTrackerURL];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello" trackURL:trackURL trackApiKey:trackApiKey];
    XCTAssertNotEqual(trackApiKey, decisionModel.trackApiKey); // not same object
    
    XCTAssertEqualObjects(@"hello", decisionModel.trackApiKey);
    [trackApiKey setString:@"world"];
    XCTAssertEqualObjects(@"hello", decisionModel.trackApiKey);
    
    // test setter
    decisionModel.trackApiKey = trackApiKey;
    XCTAssertNotEqual(trackApiKey, decisionModel.trackApiKey); // not same object
    
    XCTAssertEqualObjects(@"world", decisionModel.trackApiKey);
    [trackApiKey setString:@"hello"];
    XCTAssertEqualObjects(@"world", decisionModel.trackApiKey);
}

// The modelName set before loading the model has higher priority than
// the modelName specified in the model file.
- (void)testModelName {
    NSString *modelName = @"hello";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSError *err;
    [decisionModel load:[self modelURL] error:&err];
    XCTAssertNil(err);
    XCTAssertEqualObjects(modelName, decisionModel.modelName);
}

// modelName can be nil
- (void)testModelName_Nil {
    NSString *modelName = nil;
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
        NSLog(@"%@", decisionModel);
    } @catch(id exception) {
        NSLog(@"modelName can't be nil");
        return ;
    }
    XCTFail(@"An exception should have been thrown");
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

- (void)testLoadAsync {
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel loadAsync:[self modelURL] completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
        if(error){
            NSLog(@"loadAsync error: %@", error);
        }
        XCTAssertNotNil(compiledModel);
        XCTAssertTrue([compiledModel.modelName length] > 0);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:300];
}

- (void)testLoadAsync_nil_completion {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel loadAsync:[self modelURL] completion:nil];
    [NSThread sleepForTimeInterval:10.0f];
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
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/not/exist/TestModel.mlmodel3.gz"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:url error:&err]);
    XCTAssertNotNil(err);
    NSLog(@"loadToFail, error = %@", err);
}

- (void)testLoadSyncToFail_Nil_Error {
    NSURL *url = [NSURL URLWithString:@"http://127.0.0.1/not/exist/TestModel.mlmodel3.gz"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:url error:nil]);
}

- (void)testLoadSyncToFailWithInvalidModelFile {
    NSError *err;
    // The model exists, but is invalid
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"InvalidModel"
                         withExtension:@"dat"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertNil([decisionModel load:modelURL error:&err]);
    XCTAssertNotNil(err);
    NSLog(@"load error: %@", err);
}

- (void)testLoadAsync_invalid_model_file {
    // The model file exists, but is invalid
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"InvalidModel"
                         withExtension:@"dat"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [decisionModel loadAsync:modelURL completion:^(IMPDecisionModel * _Nullable loadedModel, NSError * _Nullable error) {
        XCTAssertNil(loadedModel);
        XCTAssertNotNil(error);
        NSLog(@"loadAsync error: %@", error);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:3];
}

- (void)testLoadAsync_url_not_exist {
    // The model file exists, but is invalid
    NSURL *modelURL = [NSURL URLWithString:@"http://127.0.0.1/not/exist/TestModel.mlmodel3.gz"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [decisionModel loadAsync:modelURL completion:^(IMPDecisionModel * _Nullable loadedModel, NSError * _Nullable error) {
        XCTAssertNil(loadedModel);
        XCTAssertNotNil(error);
        NSLog(@"loadAsync error: %@", error);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:10];
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

- (void)testLoadAsync_major_version_not_match {
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"version_6_0"
                                            withExtension:@"mlmodelc"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    [decisionModel loadAsync:modelURL completion:^(IMPDecisionModel * _Nullable loadedModel, NSError * _Nullable error) {
        XCTAssertNil(loadedModel);
        XCTAssertNotNil(error);
        NSLog(@"%@", error);
        [ex fulfill];
    }];
    [self waitForExpectations:@[ex] timeout:3];
}

- (void)testCanParseModelVersion {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    XCTAssertTrue([decisionModel canParseVersion:nil]);
    XCTAssertFalse([decisionModel canParseVersion:@""]);
    XCTAssertTrue([decisionModel canParseVersion:@"7"]);
    XCTAssertTrue([decisionModel canParseVersion:@"7.0"]);
    XCTAssertTrue([decisionModel canParseVersion:@"7.0.1"]);
    XCTAssertFalse([decisionModel canParseVersion:@" 7.0.1"]);
    XCTAssertFalse([decisionModel canParseVersion:@"8"]);
    XCTAssertFalse([decisionModel canParseVersion:@"8.0"]);
    XCTAssertFalse([decisionModel canParseVersion:@"8.0.1"]);
    XCTAssertFalse([decisionModel canParseVersion:@"abc"]);
    XCTAssertFalse([decisionModel canParseVersion:@".7"]);
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

- (void)testScore {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:[self modelURL] error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(decisionModel);
    NSArray *scores = [decisionModel score:@[@1, @2, @3]];
    XCTAssertEqual(3, [scores count]);
    NSLog(@"scores: %@", scores);
}

- (void)testScore_nil_variants {
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    @try {
        NSArray *variants = nil;
        [model score:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"variants can't be nil");
}

- (void)testScore_empty_variants {
    NSArray *variants = @[];
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    @try {
        [model score:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"variants can't be nil");
}

- (void)testScore_without_loading_model {
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < 100; i++) {
        [variants addObject:@(i)];
    }
    
    IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    NSArray<NSNumber *> *scores = [model score:variants];
    XCTAssertNotNil(scores);
    XCTAssertEqual([scores count], [variants count]);
    
    // assert that scores is in descending order
    NSInteger size = [variants count];
    for(int i = 0; i < size-1; ++i) {
        NSLog(@"score[%d] = %lf", i, [scores[i] doubleValue]);
        XCTAssertGreaterThan([scores[i] doubleValue], [scores[i+1] doubleValue]);
    }
}

- (void)testScore_consistent_encoding {
    int loop = 3;
    for(int i = 0; i < loop; ++i) {
        NSArray *variant = @[@1.0, @2];
        NSDictionary *givens = @{
            @"a": @"b",
            @"c": @{
                    @"d": @[@0.0, @1.2, @2],
                    @"e": @(true),
                    @"f": @"AsD"
            }
        };
        IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
        
        NSURL *url = [[TestUtils bundle] URLForResource:@"model.mlmodel.gz" withExtension:nil subdirectory:@"1000_list_of_numeric_variants_20_same_nested_givens_binary_reward"];
        NSError *error;
        model = [model load:url error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(model);
        
        // First call of model.score()
        // The scores should be identical up to about ~32 bits of precesion for two identical variants
        NSArray<NSNumber *> *score_1 = [[model given:givens] score:@[variant, variant]];
        XCTAssertEqual(2, [score_1 count]);
        XCTAssertEqualWithAccuracy([score_1[0] doubleValue], [score_1[1] doubleValue], 0.000001);
        NSLog(@"score#1: %lf, %lf, %lf", score_1[0].doubleValue, score_1[1].doubleValue, score_1[0].doubleValue - score_1[1].doubleValue);
        
        // Second call of model.score()
        // The scores should be identical up to about ~32 bits of precesion for two identical variants
        NSArray<NSNumber *> *score_2 = [[model given:givens] score:@[variant, variant]];
        XCTAssertEqual(2, [score_2 count]);
        XCTAssertEqualWithAccuracy([score_2[0] doubleValue], [score_2[1] doubleValue], 0.000001);
        NSLog(@"score#2: %lf, %lf, %lf", score_2[0].doubleValue, score_2[1].doubleValue, score_2[0].doubleValue - score_2[1].doubleValue);
        
        // Scores of the first and second call should differ because of the random noise
        // in the FeatureEncoder. However, if the noises happens to be very close to each
        // other, the scores can be very similar as well, and the following assertion might
        // fail.
        NSLog(@"diff score#: %lf", score_1[0].doubleValue - score_2[0].doubleValue);
        XCTAssertNotEqualWithAccuracy([score_1[0] doubleValue], [score_2[0] doubleValue], 0.000001);
    }
}

- (void)testDecide {
    IMPDecisionModel *decisionModel = [self loadedModel];
    XCTAssertNotNil(decisionModel);
    
    NSArray *variants = [self variants];
    IMPDecision *decision = [decisionModel decide:variants];
    XCTAssertEqual([variants count], [decision.rankedVariants count]);
}

- (void)testDecide_invalid_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    
    // nil variants
    @try {
        NSArray *variants = nil;
        [decisionModel decide:variants];
        XCTFail(@"variants can't be nil");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    // empty variants
    @try {
        NSArray *variants = @[];
        [decisionModel decide:variants];
        XCTFail(@"variants can't be empty");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
}

- (void)testDecide_ordered_true {
    IMPDecisionModel *decisionModel = [self loadedModel];
    XCTAssertNotNil(decisionModel);
    
    NSArray *variants = [self variants];
    
    for (int i = 0; i < 10; ++i) {
        IMPDecision *decision = [decisionModel decide:variants ordered:YES];
        XCTAssertEqual([variants count], [decision.rankedVariants count]);
        for(int j = 0; j < [variants count]; ++j) {
            XCTAssertEqualObjects(variants[j], decision.rankedVariants[j]);
        }
    }
}

- (void)testDecide_ordered_invalid_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    
    // nil variants
    @try {
        NSArray *variants = nil;
        [decisionModel decide:variants ordered:YES];
        XCTFail(@"variants can't be nil");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    // empty variants
    @try {
        NSArray *variants = @[];
        [decisionModel decide:variants ordered:YES];
        XCTFail(@"variants can't be empty");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
}

- (void)testDecideVariantsAndScores {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@2.1, @1.1, @3.1];
    IMPDecisionModel *decisionModel = [self unloadedModel];
    IMPDecision *decision = [decisionModel decide:variants scores:scores];
    XCTAssertEqualObjects(@"Hi World", decision.rankedVariants[0]);
    XCTAssertEqualObjects(@"Hello World", decision.rankedVariants[1]);
    XCTAssertEqualObjects(@"Howdy World", decision.rankedVariants[2]);
}

- (void)testDecideVariantsAndScores_invalid_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    
    @try {
        NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
        NSArray *scores = @[@2.1, @1.1];
        [decisionModel decide:variants scores:scores];
        XCTFail(@"variants size must be equal to scores size");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    @try {
        NSArray *variants = @[];
        NSArray *scores = @[];
        [decisionModel decide:variants scores:scores];
        XCTFail(@"variants and scores can't be empty");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    @try {
        NSArray *variants = @[];
        NSArray *scores = nil;
        [decisionModel decide:variants scores:scores];
        XCTFail(@"variants and scores can't be nil");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
}

- (void)testChooseFrom {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSURL *modelURL = [NSURL URLWithString:kRemoteModelURL];
    
    NSError *err;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel load:modelURL error:&err];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(err);
    IMPDecision *decision = [decisionModel chooseFrom:variants];
    IMPLog("url=%@, greeting=%@", modelURL, [decision get]);
    XCTAssertNotNil([decision get]);
    XCTAssertEqual(19, [decision.givens count]);
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

- (void)testChooseFromVariantsAndScores {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@-1.0, @0.1, @1.0];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [decisionModel chooseFrom:variants scores:scores];
    XCTAssertNotNil(decision);
    XCTAssertEqualObjects(@"Hi World", [decision get]);
    XCTAssertEqualObjects(variants, decision.variants);
    XCTAssertEqual(19, [decision.givens count]);
}

- (void)testChooseFromVariantsAndScores_size_not_equal {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@-1.0, @0.1];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseFrom:variants scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseFromVariantsAndScores_empty_variants {
    NSArray *variants = @[];
    NSArray *scores = @[];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseFrom:variants scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseFirst {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [decisionModel chooseFirst:variants];
    XCTAssertNotNil(decision);
    XCTAssertEqualObjects(@"Hello World", [decision get]);
    XCTAssertEqual(19, [decision.givens count]);
}

- (void)testChooseFirst_nil {
    NSArray *variants = nil;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseFirst:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        XCTAssertEqualObjects(kReasonVariantsNonEmpty, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseFirst_empty {
    NSArray *variants = @[];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseFirst:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        XCTAssertEqualObjects(kReasonVariantsNonEmpty, e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseRandom {
    int loop = 1000;
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        IMPDecision *decision = [decisionModel chooseRandom:variants];
        id variant = [decision get];
        XCTAssertEqual(19, [decision.givens count]);
        if(count[variant] == nil) {
            count[variant] = @1;
        } else {
            count[variant] = @(count[variant].intValue + 1);
        }
    }
    NSLog(@"%@", count);
    XCTAssertEqualWithAccuracy([count[@"Hello World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Howdy World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Hi World"] intValue], loop/3, 30);
}

- (void)testChooseRandom_empty {
    NSArray *variants = @[];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseRandom:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"variants can't be nil or empty.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testFirst {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id first = [decisionModel first:@"Hello World", @"Howdy World", @"Hi World", nil];
    XCTAssertEqualObjects(@"Hello World", first);
}

- (void)testFirst_no_argument {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel first:nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"first() expects at least one argument.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testFirst_only_one_argument {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id first = [decisionModel first:variants, nil];
    XCTAssertEqualObjects(@"Hello World", first);
}

- (void)testFirst_only_one_argument_illegal {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel first:@"Hello World", nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testFirst_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel first:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testFirst_nil_trackURL {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel first:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testRandom {
    int loop = 1000;
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [decisionModel random:@"Hello World", @"Howdy World", @"Hi World", nil];
        if(count[variant] == nil) {
            count[variant] = @1;
        } else {
            count[variant] = @(count[variant].intValue + 1);
        }
    }
    NSLog(@"%@", count);
    XCTAssertEqualWithAccuracy([count[@"Hello World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Howdy World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Hi World"] intValue], loop/3, 30);
}

- (void)testRandom_no_argument {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel random:nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"random() expects at least one argument.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testRandom_one_argument {
    int loop = 1000;
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [decisionModel random:@[@"Hello World", @"Howdy World", @"Hi World"], nil];
        if(count[variant] == nil) {
            count[variant] = @1;
        } else {
            count[variant] = @(count[variant].intValue + 1);
        }
    }
    NSLog(@"%@", count);
    XCTAssertEqualWithAccuracy([count[@"Hello World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Howdy World"] intValue], loop/3, 30);
    XCTAssertEqualWithAccuracy([count[@"Hi World"] intValue], loop/3, 30);
}

- (void)testRandom_one_argument_not_array {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel random:@"Hello World", nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"If only one argument, it must be an NSArray.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testRandom_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel random:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testRandom_nil_trackURL {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel random:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testChooseMultivariate_nil_dictionary {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        NSDictionary *variants = nil;
        [decisionModel chooseMultivariate:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseMultivariate_empty_dictionary {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel chooseMultivariate:@{}];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseMultivariate_1_variate {
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"]};

    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [decisionModel chooseMultivariate:variants];
    XCTAssertEqual(2, [decision.variants count]);
    XCTAssertEqual(19, [decision.givens count]);
    NSLog(@"combinations: %@", decision.variants);
    NSArray *expected = @[
        @{@"font":@"Italic"} ,@{@"font":@"Bold"}
    ];
    XCTAssertTrue([expected isEqualToArray:decision.variants]);
}

- (void)testChooseMultivariate_2_variates {
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"]};

    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [decisionModel chooseMultivariate:variants];
    XCTAssertEqual(4, [decision.variants count]);
    NSArray *expected = @[
        @{@"font":@"Italic", @"color":@"#000000"},
        @{@"font":@"Bold", @"color":@"#000000"},
        @{@"font":@"Italic", @"color":@"#ffffff"},
        @{@"font":@"Bold", @"color":@"#ffffff"}
    ];
    XCTAssertTrue([expected isEqualToArray:decision.variants]);
}

- (void)testChooseMultivariate_3_variates {
    NSDictionary *variants = @{
        @"font":@[@"Italic", @"Bold"],
        @"color":@[@"#000000", @"#ffffff"],
        @"size":@3
    };

    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [decisionModel chooseMultivariate:variants];
    XCTAssertEqual(4, [decision.variants count]);
    NSArray *expected = @[
        @{@"font":@"Italic", @"color":@"#000000", @"size": @3},
        @{@"font":@"Bold", @"color":@"#000000", @"size": @3},
        @{@"font":@"Italic", @"color":@"#ffffff", @"size": @3},
        @{@"font":@"Bold", @"color":@"#ffffff", @"size": @3}
    ];
    XCTAssertTrue([expected isEqualToArray:decision.variants]);
}

- (void)testOptimize {
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"], @"size":@[]};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    NSDictionary *chosen = [decisionModel optimize:variants];
    NSLog(@"chosen: %@", chosen);
    XCTAssertEqual(2, [chosen count]);
    XCTAssertNotNil(chosen[@"font"]);
    XCTAssertNotNil(chosen[@"color"]);
}

- (void)testOptimize_empty_member {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel optimize:@{@"font":@[]}];
        XCTFail("An exception should have been thrown");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

- (void)testOptimize_nil_variantMap {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        NSDictionary *variantMap = nil;
        [decisionModel optimize:variantMap];
        XCTFail("variantMap can't be nil");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

- (void)testOptimize_empty_variantMap {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel optimize:@{@"font":@[]}];
        XCTFail("variantMap can't be empty");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

// decision is tracked when calling which().
- (void)testOptimize_track {
    NSString *modelName = @"greetings";
    NSDictionary *variantMap = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"], @"size":@[]};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel optimize:variantMap];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testOptimize_nil_trackURL {
    NSString *modelName = @"greetings";
    NSDictionary *variantMap = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"], @"size":@[]};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel optimize:variantMap];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testWhich {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id chosen = [decisionModel which:@"Hi", @"Hello", @"Hey", nil];
    XCTAssertEqualObjects(@"Hi", chosen);
    
    chosen = [decisionModel which:@"Hello", nil];
    XCTAssertEqualObjects(@"Hello", chosen);
    
    NSArray *array = @[@1, @2, @3];
    chosen = [decisionModel which:array, nil];
    XCTAssertEqualObjects(array, chosen);
    
    NSArray *emptyArray = @[];
    chosen = [decisionModel which:emptyArray, nil];
    XCTAssertEqualObjects(@[], chosen);
    
    NSDictionary *dict = @{@"color":@"#ffffff"};
    chosen = [decisionModel which:dict, nil];
    XCTAssertEqualObjects(dict, chosen);
    
    NSDictionary *emptyDict = @{};
    chosen = [decisionModel which:emptyDict, nil];
    XCTAssertEqualObjects(emptyDict, chosen);
}

- (void)testWhich_no_argument {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel which:nil];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

// decision is tracked when calling which().
- (void)testWhich_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel which:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testWhich_nil_trackURL {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel which:@"hi", @"hello", @"hey", nil];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testWhichFrom {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSString *chosen = [decisionModel whichFrom:[self variants]];
    XCTAssertEqualObjects(@"Hello World", chosen);
}

- (void)testWhichFrom_nil_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    @try {
        NSArray *variants = nil;
        [decisionModel whichFrom:variants];
        XCTFail(@"variants can't be nil");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

- (void)testWhichFrom_empty_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    @try {
        NSArray *variants = @[];
        [decisionModel whichFrom:variants];
        XCTFail(@"variants can't be empty");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

// decision is tracked when calling which().
- (void)testWhichFrom_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel whichFrom:@[@"hi", @"hello", @"hey"]];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testWhichFrom_nil_trackURL {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel whichFrom:@[@"hi", @"hello", @"hey"]];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testRank {
    NSArray *variants = [self variants];
    IMPDecisionModel *decisionModel = [self loadedModel];
    NSArray *rankedVariants = [decisionModel rank:variants];
    XCTAssertEqual([variants count], [rankedVariants count]);
    for(int i = 0; i < [variants count]; ++i) {
        XCTAssertTrue([rankedVariants containsObject:variants[i]]);
    }
}

- (void)testRank_nil_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    @try {
        NSArray *variants = nil;
        [decisionModel rank:variants];
        XCTFail(@"variants can't be nil");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

- (void)testRank_empty_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    @try {
        NSArray *variants = @[];
        [decisionModel whichFrom:variants];
        XCTFail(@"variants can't be empty");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

// decision is tracked when calling which().
- (void)testRank_track {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel rank:@[@"hi", @"hello", @"hey"]];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertNotEqualObjects(lastDecisionId, newDecisionid);
}

// When trackURL is nil, decision is not tracked and no exceptions thrown.
- (void)testRank_nil_trackURL {
    NSString *modelName = @"greetings";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    [decisionModel setTrackURL:nil];
    NSString *lastDecisionId = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    [decisionModel rank:@[@"hi", @"hello", @"hey"]];
    NSString *newDecisionid = [IMPDecisionTracker lastDecisionIdOfModel:modelName];
    XCTAssertNotNil(newDecisionid);
    XCTAssertEqualObjects(lastDecisionId, newDecisionid);
}

- (void)testFullFactorialVariants_nil_dictionary {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        NSDictionary *variants = nil;
        [decisionModel fullFactorialVariants:variants];
        XCTFail(@"variantMap can't be nil");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
    }
}

- (void)testFullFactorialVariants_empty_dictionary {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [decisionModel fullFactorialVariants:@{}];
        XCTFail(@"variantMap can't be empty");
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
    }
}

- (void)testFullFactorialVariants_1_variate {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSArray *variants = [decisionModel fullFactorialVariants:@{@"font":@[@"Italic", @"Bold"]}];
    XCTAssertEqual(2, [variants count]);
    NSArray *expected = @[
        @{@"font":@"Italic"} ,@{@"font":@"Bold"}
    ];
    NSLog(@"variants: %@", variants);
    XCTAssertEqualObjects(expected, variants);
}

- (void)testFullFactorialVariants_2_variates {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSArray *variants = [decisionModel fullFactorialVariants:@{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"]}];
    NSArray *expected = @[
        @{@"font":@"Italic", @"color":@"#000000"},
        @{@"font":@"Bold", @"color":@"#000000"},
        @{@"font":@"Italic", @"color":@"#ffffff"},
        @{@"font":@"Bold", @"color":@"#ffffff"}
    ];
    NSLog(@"variants: %@", variants);
    XCTAssertEqualObjects(expected, variants);
}

- (void)testFullFactorialVariants_3_variates {
    NSDictionary *variantMap = @{
        @"font":@[@"Italic", @"Bold"],
        @"color":@[@"#000000", @"#ffffff"],
        @"size":@3
    };

    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSArray *variants = [decisionModel fullFactorialVariants:variantMap];
    NSArray *expected = @[
        @{@"font":@"Italic", @"color":@"#000000", @"size": @3},
        @{@"font":@"Bold", @"color":@"#000000", @"size": @3},
        @{@"font":@"Italic", @"color":@"#ffffff", @"size": @3},
        @{@"font":@"Bold", @"color":@"#ffffff", @"size": @3}
    ];
    NSLog(@"variants: %@", variants);
    XCTAssertEqualObjects(expected, variants);
}

- (void)testFullFactorialVariants_empty_array {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSArray *variants = [decisionModel fullFactorialVariants:@{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"], @"size":@[]}];
    NSArray *expected = @[
        @{@"font":@"Italic", @"color":@"#000000"},
        @{@"font":@"Bold", @"color":@"#000000"},
        @{@"font":@"Italic", @"color":@"#ffffff"},
        @{@"font":@"Bold", @"color":@"#ffffff"}
    ];
    NSLog(@"variants: %@", variants);
    XCTAssertEqualObjects(expected, variants);
}

- (void)testRankWithScores {
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

- (void)testRankWithScores_illegal_arguments {
    @try {
        [IMPDecisionModel rank:@[@"Hi", @"Hello"] withScores:@[@1.0]];
        XCTFail(@"variants number and scores number must be equal.");
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
    }
    
    @try {
        [IMPDecisionModel rank:@[@"Hi", @"Hello"] withScores:@[@1.0, @2.0, @3.0]];
        XCTFail(@"variants number and scores number must be equal.");
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
    }
    
    @try {
        [IMPDecisionModel rank:@[] withScores:@[]];
        XCTFail(@"variants and socres can't be nil or empty");
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
    }
    
    @try {
        NSArray *variants = nil;
        [IMPDecisionModel rank:@[@"Hi", @"Hello"] withScores:variants];
        XCTFail(@"variants and scores can't be nil or empty.");
    } @catch (NSException *e) {
        NSLog(@"name=%@, reason=%@", e.name, e.reason);
    }
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

- (void)testValidateModels {
    NSURL *testsuiteURL = [[TestUtils bundle] URLForResource:@"model_test_suite.txt" withExtension:nil];
    NSString *allTestsStr = [[NSString alloc] initWithContentsOfURL:testsuiteURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue(allTestsStr.length>1);
    
    if([allTestsStr hasSuffix:@"\n"]){
        allTestsStr = [allTestsStr substringToIndex:allTestsStr.length-1];
    }
    
    NSArray *allTestCases = [allTestsStr componentsSeparatedByString:@"\n"];
    XCTAssertTrue(allTestCases.count >= 1);
    
    for(NSString *testCase in allTestCases) {
        NSString *jsonFileName = [NSString stringWithFormat:@"%@.json", testCase];
        NSURL *url = [[TestUtils bundle] URLForResource:jsonFileName withExtension:nil subdirectory:testCase];
        NSData *data = [NSData dataWithContentsOfURL:url];
        XCTAssertNotNil(data);
        
        NSError *err = nil;
        NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        XCTAssertNil(err);
        
        XCTAssertTrue([self verifyModel:testCase withData:root]);
    }
}

- (BOOL)verifyModel:(NSString *)path withData:(NSDictionary *)root {
    NSLog(@"verifyModel: <<<<<<<< %@ >>>>>>>>", path);
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"model.mlmodel.gz" withExtension:nil subdirectory:path];
    
    NSDictionary *testCase = [root objectForKey:@"test_case"];
    XCTAssertNotNil(testCase);
    
    double noise = [[testCase objectForKey:@"noise"] doubleValue];
    NSArray *variants = [testCase objectForKey:@"variants"];
    NSArray *givens = [testCase objectForKey:@"givens"];
    NSArray *expectedOutputs = [root objectForKey:@"expected_output"];
    XCTAssertNotNil(variants);
    XCTAssertNotNil(givens);
    
    IMPDecisionModel *decisionModel = [[[IMPDecisionModel alloc] initWithModelName:@"hello"] load:modelURL error:nil];
    decisionModel.enableTieBreaker = NO;
    decisionModel.featureEncoder.noise = noise;
    
    if([givens isEqual:[NSNull null]]) {
        NSArray *scores = [decisionModel score:variants];
        NSArray *expectedScores = [expectedOutputs[0] objectForKey:@"scores"];
        XCTAssertEqual([scores count], [expectedScores count]);
        XCTAssertTrue([scores count] > 0);
        
        for(int j = 0; j < [scores count]; ++j) {
            XCTAssertEqualWithAccuracy([expectedScores[j] doubleValue],
                                       [scores[j] doubleValue],
                                       pow(2, -19));
        }
    } else {
        for(int i = 0; i < [givens count]; ++i) {
            NSLog(@"%d/%ld", i, [givens count]);
            NSArray *scores;
            if([givens[i] isKindOfClass:[NSDictionary class]]) {
                scores = [[decisionModel given:givens[i]] score:variants];
            } else if([givens[i] isEqual:[NSNull null]]) {
                scores = [decisionModel score:variants];
            } else {
                XCTFail(@"unexpected type of givens");
            }
            NSArray *expectedScores = [expectedOutputs[i] objectForKey:@"scores"];
            XCTAssertEqual([scores count], [expectedScores count]);
            XCTAssertTrue([scores count] > 0);
            
            for(int j = 0; j < [scores count]; ++j) {
//                NSLog(@"%d, %d, variant: %@\n, givens: %@", j, i, variants[j], givens[i]);
                XCTAssertEqualWithAccuracy([expectedScores[j] doubleValue],
                                           [scores[j] doubleValue],
                                           pow(2, -18));
            }
        }
    }
    return YES;
}

- (void)testAddReward {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    [[decisionModel chooseFrom:variants] get];
    [decisionModel addReward:0.1];
}

- (void)testAddReward_nil_trackURL {
    @try {
        IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting" trackURL:nil trackApiKey:nil];
        [decisionModel addReward:0.1];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(e.name, IMPIllegalStateException);
        return ;
    }
    XCTFail(@"trackURL can't be nil when calling DecisionModel.addReward()");
}

- (void)testAddRewardForDecision {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    [decisionModel addReward:0.1 decision:@"abc"];
}

- (void)testAddRewardForDecision_empty_decisionId {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    @try {
        [decisionModel addReward:0.1 decision:@""];
    } @catch(NSException *e) {
        return ;
    }
    XCTFail(@"decisionId can't be empty");
}

- (void)testAddRewardForDecision_nil_decisionId {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    NSString *decisionId = nil;
    @try {
        [decisionModel addReward:0.1 decision:decisionId];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        return ;
    }
    XCTFail(@"decisionId can't be nil");
}

- (void)testAddRewardForDecision_nil_trackURL {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    decisionModel.trackURL = nil;
    @try {
        [decisionModel addReward:0.1 decision:@"decision_id"];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        return ;
    }
    XCTFail(@"decisionId can't be nil");
}

- (void)testAddRewardForDecision_positive_infinity {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    @try {
        [decisionModel addReward:INFINITY decision:@"decision_id"];
    } @catch(NSException *e) {
        return ;
    }
    XCTFail(@"decisionId can't be nil");
}

- (void)testAddRewardForDecision_negative_infinity {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    @try {
        [decisionModel addReward:-INFINITY decision:@"decision_id"];
    } @catch(NSException *e) {
        return ;
    }
    XCTFail(@"decisionId can't be nil");
}

- (void)testAddRewardForDecision_nan {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    @try {
        [decisionModel addReward:NAN decision:@"decision_id"];
    } @catch(NSException *e) {
        return ;
    }
    XCTFail(@"decisionId can't be nil");
}

- (void)testGivensProvider_thread_safe {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greeting"];
    
    for(int i = 0; i < 100; ++i) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [decisionModel score:variants];
        });
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            decisionModel.givensProvider = [[AppGivensProvider alloc] init];
        });
    }
    
    [NSThread sleepForTimeInterval:2.0f];
}

- (void)testA2Z_Model {
    NSError *error;
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"a_z_model.mlmodel.gz" withExtension:nil];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"a-z"];
    [decisionModel load:modelURL error:&error];
    XCTAssertNil(error);
    
    NSURL *jsonURL = [[TestUtils bundle] URLForResource:@"a_z.json" withExtension:nil];
    NSData *data = [NSData dataWithContentsOfURL:jsonURL];
    XCTAssertNotNil(data);
    
    NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    XCTAssertNil(error);
    
    NSArray *variants = root[@"test_case"][@"variants"];
    XCTAssertEqual(26, [variants count]);
    
    double noise = [root[@"test_case"][@"noise"] doubleValue];
    decisionModel.featureEncoder.noise = noise;
    NSLog(@"noise: %lf", noise);
    
    NSArray *expectedScores = root[@"expected_output"][0][@"scores"];
    XCTAssertEqual(26, [expectedScores count]);
    
    NSArray<NSNumber *> *scores = [decisionModel score:variants];
    NSLog(@"scores: %@", scores);
    for(int i = 0; i < 26; ++i) {
        XCTAssertEqualWithAccuracy([expectedScores[i] doubleValue], [scores[i] doubleValue], 0.000002);
    }
}

- (void)testWarningOnceArrayEncoding {
    NSError *error;
    NSURL *modelURL = [[TestUtils bundle] URLForResource:@"a_z_model.mlmodel.gz" withExtension:nil];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"a-z"];
    [decisionModel load:modelURL error:&error];
    XCTAssertNil(error);
    
    [[decisionModel chooseFrom:@[@[@1, @2], @[@3, @4]]] get];
}

- (void)testIsLoaded_loaded {
    XCTAssertTrue([[self loadedModel] isLoaded]);
}

- (void)testIsLoaded_not_loaded {
    XCTAssertFalse([[self unloadedModel] isLoaded]);
}

@end
