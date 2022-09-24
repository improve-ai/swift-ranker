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

@property(nonatomic, copy) NSArray *rankedVariants;

@property(nonatomic, strong) NSDictionary *givens;

@end

@interface IMPDecisionContextTest : XCTestCase

@property (strong, nonatomic) NSURL *modelURL;

@property (strong, nonatomic) NSDictionary *givens;

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

- (NSDictionary *)givens {
    if(_givens == nil) {
        _givens = @{@"lang":@"en"};
    }
    return _givens;
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

- (nullable IMPDecisionModel *)loadedModel {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    return [decisionModel load:[NSURL URLWithString:kRemoteModelURL] error:nil];
}

- (IMPDecisionModel *)unloadedModel {
    return [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
}

- (void)testDecide {
    IMPDecisionModel *decisionModel = [self loadedModel];
    XCTAssertNotNil(decisionModel);
    
    NSArray *variants = [self variants];
    IMPDecision *decision = [[decisionModel given:nil] decide:variants];
    XCTAssertEqual([variants count], [decision.rankedVariants count]);
}

- (void)testDecide_invalid_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    
    // nil variants
    @try {
        NSArray *variants = nil;
        [[decisionModel given:nil] decide:variants];
        XCTFail(@"variants can't be nil");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    // empty variants
    @try {
        NSArray *variants = @[];
        [[decisionModel given:nil] decide:variants];
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
        IMPDecision *decision = [[decisionModel given:nil] decide:variants ordered:YES];
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
        [[decisionModel given:nil] decide:variants ordered:YES];
        XCTFail(@"variants can't be nil");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
    
    // empty variants
    @try {
        NSArray *variants = @[];
        [[decisionModel given:nil] decide:variants ordered:YES];
        XCTFail(@"variants can't be empty");
    } @catch (NSException *e){
        NSLog(@"%@", e);
    }
}

- (void)testChooseFrom {
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [decisionModel given:givens];
    IMPDecision *decision = [decisionContext chooseFrom:[self variants]];
    XCTAssertEqual(20, [decision.givens count]);
}

- (void)testChooseFrom_nil_givens {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [decisionModel given:nil];
    IMPDecision *decision = [decisionContext chooseFrom:[self variants]];
    XCTAssertEqual(19, [decision.givens count]);
}

- (void)testChooseFrom_nil_variants {
    NSArray *variants = nil;
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [decisionModel given:givens];
    @try {
        [decisionContext chooseFrom:variants];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        XCTAssertEqualObjects(@"variants can't be nil or empty.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testChooseFrom_empty_variants {
    NSArray *variants = @[];
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecisionContext *decisionContext = [decisionModel given:givens];
    @try {
        [decisionContext chooseFrom:variants];
    } @catch(NSException *e) {
        NSLog(@"exception: %@", e);
        XCTAssertEqualObjects(@"variants can't be nil or empty.", e.reason);
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
    XCTAssertEqualObjects(@"Howdy World", [decision get]);
}

- (void)testChooseFromVariantsAndScores_nil_givens {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    IMPDecision *decision = [[decisionModel given:self.givens] chooseFrom:variants scores:scores];
    XCTAssertEqual(20, [decision.givens count]);
    XCTAssertEqualObjects(@"Howdy World", [decision get]);
}

- (void)testChooseFromVariantsAndScores_nil_variants {
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        NSArray *variants = nil;
        [[decisionModel given:self.givens] chooseFrom:variants scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be nil");
}

- (void)testChooseFromVariantsAndScores_empty_variants {
    NSArray *scores = @[@0.1, @0.8, @0.4];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:self.givens] chooseFrom:@[] scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be empty");
}

- (void)testChooseFromVariantsAndScores_invalid_size {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSArray *scores = @[@0.1, @0.8, @0.4, @.5];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:self.givens] chooseFrom:variants scores:scores];
    } @catch(NSException *e) {
        NSLog(@"%@, %@", e.name, e.reason);
        return ;
    }
    XCTFail("variants can't be empty");
}

- (void)testChooseFirst {
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    IMPDecision *decision = [[decisionModel given:self.givens] chooseFirst:variants];
    XCTAssertEqualObjects(@"en", decision.givens[@"lang"]);
    XCTAssertEqual(20, [decision.givens count]);
    XCTAssertEqualObjects(@"Hello World", [decision get]);
}

- (void)testChooseFirst_nil_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    @try {
        NSArray *variants = nil;
        [[decisionModel given:self.givens] chooseFirst:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"variants can't be nil or empty.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testChooseFirst_empty_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    @try {
        [[decisionModel given:self.givens] chooseFirst:@[]];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"variants can't be nil or empty.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testFirst {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id first = [[decisionModel given:self.givens] first:@"Hello", @"Howdy", @"Hi", nil];
    XCTAssertEqualObjects(@"Hello", first);
}

- (void)testFirst_one_argument {
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    id first = [[decisionModel given:givens] first:@[@"Hello", @"Howdy", @"Hi"], nil];
    XCTAssertEqualObjects(@"Hello", first);
}

- (void)testFirst_one_argument_not_array {
    NSDictionary *givens = @{@"lang":@"en"};
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:givens] first:@"Hello", nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"If only one argument, it must be an NSArray.", e.reason);
        return ;
    }
    XCTFail("An execption should have been thrown.");
}

- (void)testChooseRandom {
    int loop = 1000;
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [[[decisionModel given:self.givens] chooseRandom:variants] get];
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

- (void)testRandom {
    int loop = 1000;
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [[decisionModel given:self.givens] random:@"Hello World", @"Howdy World", @"Hi World", nil];
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

- (void)testRandom_one_argument {
    int loop = 1000;
    NSMutableDictionary<NSString *, NSNumber *> *count = [[NSMutableDictionary alloc] init];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    decisionModel.trackURL = nil;
    for(int i = 0; i < loop; ++i) {
        id variant = [[decisionModel given:self.givens] random:@[@"Hello World", @"Howdy World", @"Hi World"], nil];
        if(count[variant] == nil) {
            count[variant] = @1;
        } else {
            count[variant] = @(count[variant].intValue + 1);
        }
    }
    NSLog(@"%@", count);
    XCTAssertEqualWithAccuracy([count[@"Hello World"] intValue], loop/3, 50);
    XCTAssertEqualWithAccuracy([count[@"Howdy World"] intValue], loop/3, 50);
    XCTAssertEqualWithAccuracy([count[@"Hi World"] intValue], loop/3, 50);
}

- (void)testRandom_one_argument_not_array {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:self.givens] random:@"Hello World", nil];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(@"If only one argument, it must be an NSArray.", e.reason);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testScore_nil_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    @try {
        NSArray *variants = nil;
        [decisionContext score:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"variants can't be nil");
}

- (void)testScore_empty_variants {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
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
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    NSArray<NSNumber *> *scores = [decisionContext score:variants];
    XCTAssertEqual([variants count], [scores count]);
    NSLog(@"scores: %@", scores);
}

- (void)testWhich {
    IMPDecisionContext *decisionContext = [[self unloadedModel] given:self.givens];
    
    id chosen = [decisionContext which:@"Hi", @"Hello", @"Hey", nil];
    XCTAssertEqualObjects(@"Hi", chosen);
    
    chosen = [decisionContext which:@"Hello", nil];
    XCTAssertEqualObjects(@"Hello", chosen);
    
    NSArray *array = @[@1, @2, @3];
    chosen = [decisionContext which:array, nil];
    XCTAssertEqualObjects(array, chosen);
    
    NSArray *emptyArray = @[];
    chosen = [decisionContext which:emptyArray, nil];
    XCTAssertEqualObjects(@[], chosen);
    
    NSDictionary *dict = @{@"color":@"#ffffff"};
    chosen = [decisionContext which:dict, nil];
    XCTAssertEqualObjects(dict, chosen);
    
    NSDictionary *emptyDict = @{};
    chosen = [decisionContext which:emptyDict, nil];
    XCTAssertEqualObjects(emptyDict, chosen);
}

- (void)testWhich_no_argument {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    @try {
        [[decisionModel given:nil] which:nil];
    } @catch(NSException *e) {
        NSLog(@"%@", e);
        return ;
    }
    XCTFail(@"An exception should have been thrown");
}

- (void)testWhichFrom {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    NSString *chosen = [[decisionModel given:nil] whichFrom:[self variants]];
    XCTAssertEqualObjects(@"Hello World", chosen);
}

- (void)testWhichFrom_nil_empty_variants {
    IMPDecisionModel *decisionModel = [self unloadedModel];
    @try {
        NSArray *variants = nil;
        [[decisionModel given:nil] whichFrom:variants];
        XCTFail(@"variants can't be nil");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
    
    @try {
        NSArray *variants = @[];
        [[decisionModel given:nil] whichFrom:variants];
        XCTFail(@"variants can't be empty");
    } @catch(NSException *e) {
        NSLog(@"%@", e);
    }
}

- (void)testRank {
    NSArray *variants = [self variants];
    IMPDecisionModel *decisionModel = [self loadedModel];
    NSArray *rankedVariants = [[decisionModel given:nil] rank:variants];
    XCTAssertEqual([variants count], [rankedVariants count]);
    for(int i = 0; i < [variants count]; ++i) {
        XCTAssertTrue([rankedVariants containsObject:variants[i]]);
    }
}

- (void)testChooseMultivariate {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"]};
    
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    IMPDecision *decision = [decisionContext chooseMultivariate:variants];
    NSLog(@"chosen: %@", [decision get]);
}

- (void)testChooseMultivariate_nil_variants {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    @try {
        NSDictionary *variants = nil;
        [decisionContext chooseMultivariate:variants];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testChooseMultivariate_empty_variants {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    @try {
        [decisionContext chooseMultivariate:@{}];
    } @catch(NSException *e) {
        XCTAssertEqualObjects(NSInvalidArgumentException, e.name);
        return ;
    }
    XCTFail(@"An exception should have been thrown.");
}

- (void)testOptimize {
    NSError *error;
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel = [decisionModel load:self.modelURL error:&error];
    XCTAssertNotNil(decisionModel);
    XCTAssertNil(error);
    
    NSDictionary *variants = @{@"font":@[@"Italic", @"Bold"], @"color":@[@"#000000", @"#ffffff"]};
    
    IMPDecisionContext *decisionContext = [decisionModel given:self.givens];
    NSDictionary *chosen = [decisionContext optimize:variants];
    NSLog(@"chosen: %@", chosen);
    XCTAssertEqual(2, [chosen count]);
    XCTAssertNotNil(chosen[@"font"]);
    XCTAssertNotNil(chosen[@"color"]);
}

@end
