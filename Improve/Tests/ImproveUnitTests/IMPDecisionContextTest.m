//
//  IMPDecisionContextTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 1/14/22.
//  Copyright © 2022 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionModel.h"
#import "IMPDecisionContext.h"

extern NSString * const kRemoteModelURL;

@interface IMPDecision ()

@property(nonatomic, readonly, nullable) id best;

@property(nonatomic, strong) NSArray *scores;

@property(nonatomic, strong) NSDictionary *givens;

@property (nonatomic, readonly) int tracked;

@end

@interface IMPDecisionContextTest : XCTestCase

@property (strong, nonatomic) NSURL *modelURL;

@end

@implementation IMPDecisionContextTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSArray *)variants {
    return @[@"Hello World", @"Howdy World", @"Hi World"];
}

- (NSURL *)modelURL {
    if(_modelURL == nil) {
        _modelURL = [NSURL URLWithString:kRemoteModelURL];
    }
    return _modelURL;
}

- (void)testChooseFrom {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    IMPDecision *decision = [decisionContext chooseFrom:[self variants]];
    XCTAssertNotNil(decision.best);
    XCTAssertNotNil(decision.givens);
    XCTAssertNotNil(decision.scores);
}

- (void)testChooseFrom_nil_variants {
    NSArray *variants = nil;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext chooseFrom:variants];
    } @catch(NSException *e) {
        XCTAssertEqual(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testChooseFrom_empty_variants {
    NSArray *variants = @[];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext chooseFrom:variants];
    } @catch(NSException *e) {
        XCTAssertEqual(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testScore_nil_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext score:nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"variants can't be nil");
}

- (void)testScore_empty_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext score:@[]];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"variants can't be nil");
}

- (void)testScore_valid {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    NSArray<NSNumber *> *scores = [decisionContext score:variants];
    XCTAssertEqual([variants count], [scores count]);
    NSLog(@"scores: %@", scores);
}

- (void)testWhich {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    id best = [decisionContext which:@"Hello World", @"Howdy World", @"Hi World", nil];
    XCTAssertNotNil(best);
}

- (void)testChooseMultiVariate {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"]};
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    [decisionContext chooseMultiVariate:variants];
}

@end
