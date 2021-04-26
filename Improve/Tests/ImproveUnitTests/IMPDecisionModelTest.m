//
//  DecisionModelTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/22/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionModel.h"
#import "IMPDecision.h"
#import "IMPUtils.h"
#import "TestUtils.h"

@interface IMPDecisionModelTest : XCTestCase

@property (strong, nonatomic) NSArray *urlList;

@end

@implementation IMPDecisionModelTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSArray *)urlList{
    if(_urlList == nil){
        _urlList = @[
            [NSURL fileURLWithPath:@"/Users/phx/Documents/improve-ai/TestModel.mlmodel"],
            [NSURL URLWithString:@"http://192.168.1.101:14000/static/improve-ai/TestModel.mlmodel"],
            [[TestUtils bundle] URLForResource:@"TestModel"
                                 withExtension:@"mlmodelc"]];
    }
    return _urlList;
}

- (void)testLoadAsync{
    for(NSURL *url in self.urlList){
        XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
        [IMPDecisionModel loadAsync:url completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable error) {
            if(error){
                NSLog(@"loadAsync error: %@", error);
            }
            XCTAssert([NSThread isMainThread]);
            XCTAssertNotNil(compiledModel);
            [ex fulfill];
        }];
        [self waitForExpectations:@[ex] timeout:300];
    }
}

- (void)testLoadSync{
    for(NSURL *url in self.urlList){
        IMPDecisionModel *decisionModel = [IMPDecisionModel load:url];
        XCTAssertNotNil(decisionModel);
    }
}

- (void)testLoadSyncFromNonMainThread{
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        XCTAssert(![NSThread isMainThread]);
        for(NSURL *url in self.urlList){
            IMPDecisionModel *decisionModel = [IMPDecisionModel load:url];
            XCTAssertNotNil(decisionModel);
        }
        [ex fulfill];
    });
    [self waitForExpectations:@[ex] timeout:300];
}

- (void)testDescendingGaussians{
    int n = 4000;
    double total = 0.0;
    
    NSArray *array = [IMPUtils generateDescendingGaussians:n];
    
    for(int i = 0; i < n; ++i){
        NSLog(@"%f", [[array objectAtIndex:i] doubleValue]);
        total += [[array objectAtIndex:i] doubleValue];
    }
    
    NSLog(@"median = %f, average = %f", [[array objectAtIndex:n/2] doubleValue], total / n);
    double diff = ABS([[array objectAtIndex:n/2] doubleValue] * 100);
    XCTAssert(diff < 10); // might fail here
}

- (void)testChooseFrom {
    NSArray *variants = @[];
    
//    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *context = @{@"language": @"cowboy"};
    for(NSURL *url in self.urlList){
        IMPDecisionModel *decisionModel = [IMPDecisionModel load:url];
        XCTAssertNotNil(decisionModel);
        NSString *greeting = [[[decisionModel chooseFrom:variants] given:context] get];
        IMPLog("url=%@, greeting=%@", url, greeting);
        XCTAssertNotNil(greeting);
    }
    
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.101/TestModel.mlmodel3.gz"];
    NSString *greeting = [[[[IMPDecisionModel load:url] chooseFrom:variants] given:context] get];
    NSLog(@"greeting: %@", greeting);
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

@end
