//
//  DecisionModelTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/22/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionModel.h"
#import "IMPUtils.h"

@interface DecisionModelTest : XCTestCase

@property (strong, nonatomic) NSArray *urlList;

@end

@implementation DecisionModelTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSArray *)urlList{
    if(_urlList == nil){
        _urlList = @[
            @"/Users/phx/Documents/improve-ai/TestModel.mlmodel",
            @"http://192.168.1.101:14000/static/improve-ai/TestModel.mlmodel"];
    }
    return _urlList;
}

- (void)testLoadAsync{
    for(NSString *urlstr in self.urlList){
        NSURL *url = [urlstr hasPrefix:@"http"] ? [NSURL URLWithString:urlstr] : [NSURL fileURLWithPath:urlstr];
        XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
        [IMPDecisionModel loadAsync:url completion:^(MLModel * _Nullable compiledModel, NSError * _Nullable error) {
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
    for(NSString *urlstr in self.urlList){
        NSURL *url = [urlstr hasPrefix:@"http"] ? [NSURL URLWithString:urlstr] : [NSURL fileURLWithPath:urlstr];
        MLModel *compiledModel = [IMPDecisionModel load:url];
        XCTAssertNotNil(compiledModel);
    }
}

- (void)testLoadSyncFromNonMainThread{
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        XCTAssert(![NSThread isMainThread]);
        for(NSString *urlstr in self.urlList){
            NSURL *url = [urlstr hasPrefix:@"http"] ? [NSURL URLWithString:urlstr] : [NSURL fileURLWithPath:urlstr];
            MLModel *compiledModel = [IMPDecisionModel load:url];
            XCTAssertNotNil(compiledModel);
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

@end
