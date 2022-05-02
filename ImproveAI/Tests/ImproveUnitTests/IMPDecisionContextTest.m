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

extern NSString * const kTrackerURL;

extern NSString *const kTrackApiKey;

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
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
    IMPDecisionModel.defaultTrackApiKey = kTrackApiKey;
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
        NSLog(@"exception: %@", e);
        XCTAssertEqual(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testChooseFromVariantsAndScores {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *givens = @{@"lang":@"en"};
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [[decisionModel given:givens] chooseFrom:variants scores:scores];
    XCTAssertEqual(20, [decision.givens count]);
    XCTAssertEqualObjects(@"en", decision.givens[@"lang"]);
    XCTAssertEqualObjects(@"Howdy World", decision.best);
}

- (void)testChooseFromVariantsAndScores_nil_givens {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [[decisionModel given:nil] chooseFrom:variants scores:scores];
    XCTAssertEqual(19, [decision.givens count]);
    XCTAssertEqualObjects(@"Howdy World", decision.best);
}

- (void)testChooseFromVariantsAndScores_nil_variants {
    NSDictionary *givens = @{@"lang":@"en"};
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:givens] chooseFrom:nil scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be nil");
}

- (void)testChooseFromVariantsAndScores_empty_variants {
    NSDictionary *givens = @{@"lang":@"en"};
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:givens] chooseFrom:@[] scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be empty");
}

- (void)testChooseFromVariantsAndScores_invalid_size {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *givens = @{@"lang":@"en"};
    NSArray *scores = @[@0.1, @0.8, @0.4, @.5];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:givens] chooseFrom:variants scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be empty");
}

- (void)testChooseFirst {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[decisionModel given:givens] chooseFirst:variants];
    XCTAssertEqualObjects(@"en", decision.givens[@"lang"]);
    XCTAssertEqual(20, [decision.givens count]);
    XCTAssertEqualObjects(@"Hello World", [decision get]);
}

- (void)testFirst {
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id first = [[decisionModel given:givens] first:@"Hello", @"Howdy", @"Hi", nil];
    XCTAssertEqualObjects(@"Hello", first);
}

- (void)testChooseRandom {
    int loop = 1000;
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [[[decisionModel given:nil] chooseRandom:variants] get];
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
    XCTFail(@"variants can't be empty");
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

- (void)testWhich_empty_dict {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext which:@{}, nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testWhich_empty_array {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext which:@[], nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
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

- (void)testChooseMultiVariate_nil_variants {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext chooseMultiVariate:nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testChooseMultiVariate_empty_variants {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [[IMPDecisionContext alloc] initWithModel:decisionModel andGivens:nil];
    @try {
        [decisionContext chooseMultiVariate:@{}];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

@end
