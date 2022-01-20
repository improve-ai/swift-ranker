//
//  AppGivensProviderTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 10/28/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppGivensProvider.h"
#import "IMPDecisionModel.h"
#import "IMPDecision.h"

extern NSString * const kTrackerURL;

@interface AppGivensProviderTest : XCTestCase

@end

@interface AppGivensProvider()

- (IMPDeviceInfo *)parseDeviceInfo:(NSString *)platform;

- (NSDecimalNumber *)improveVersion:(NSString *)version;

- (double)rewardOfModel:(NSString *)modelName;

@end

@implementation AppGivensProviderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
    IMPDecisionModel.defaultTrackURL = [NSURL URLWithString:kTrackerURL];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAppGivensProvider {
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    AppGivensProvider *appGivensProvider = [[AppGivensProvider alloc] init];
    NSDictionary *givens = [appGivensProvider givensForModel:decisionModel givens:@{}];
    NSLog(@"app givens: %@", givens);
    
    // nil carrier excluded from the givens
    XCTAssertEqual(19, [givens count]);
}

- (BOOL)isDecimalNumberEqual:(NSDecimalNumber *)t1 :(NSDecimalNumber *)t2 {
    return [t1 compare:t2] == NSOrderedSame;
}

- (void)testImproveVersion {
    AppGivensProvider *givensProvider = [[AppGivensProvider alloc] init];
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"6.1.123"]
                                            :[NSDecimalNumber decimalNumberWithString:@"6.001123"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"6.1"]
                                            :[NSDecimalNumber decimalNumberWithString:@"6.001"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"6"]
                                            :[NSDecimalNumber decimalNumberWithString:@"6"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"10.1.15"]
                                            :[NSDecimalNumber decimalNumberWithString:@"10.001015"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@""]
                                            :[NSDecimalNumber decimalNumberWithString:@"0"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"1."]
                                            :[NSDecimalNumber decimalNumberWithString:@"1"]]);
    
    XCTAssertTrue([self isDecimalNumberEqual:[givensProvider improveVersion:@"."]
                                            :[NSDecimalNumber decimalNumberWithString:@"0"]]);
}

- (void)testAddReward_decision {
    NSString *modelName = @"greeting";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    IMPDecision *decision = [decisionModel chooseFrom:@[@1, @2, @3]];
    [decision get];
    
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    double oldTotalRewardOfModel = [provider rewardOfModel:modelName];
    [decision addReward:0.1];
    double newTotalRewardOfModel = [provider rewardOfModel:modelName];
    XCTAssertEqualWithAccuracy(oldTotalRewardOfModel+0.1, newTotalRewardOfModel, 0.000001);
}

- (void)testAddReward_decisionModel {
    NSString *modelName = @"greeting";
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:modelName];
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    double oldTotalRewardOfModel = [provider rewardOfModel:modelName];
    [decisionModel addReward:0.1];
    double newTotalRewardOfModel = [provider rewardOfModel:modelName];
    XCTAssertEqualWithAccuracy(oldTotalRewardOfModel+0.1, newTotalRewardOfModel, 0.000001);
}

extern NSString *const kLanguageKey;
- (void)testOverlappingKeys {
    NSDictionary *givens = @{
       kLanguageKey : @"hi"
    };
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    
    NSDictionary *allGivens = [provider givensForModel:decisionModel givens:nil];
    NSLog(@"allGivens: %@", allGivens);
    
    // assert that kLanguageKey exists in AppGivensProvider givens
    XCTAssertTrue([allGivens[kLanguageKey] length] > 0);
    XCTAssertNotEqualObjects(@"hi", allGivens[kLanguageKey]);
    
    allGivens = [provider givensForModel:decisionModel givens:givens];
    NSLog(@"allGivens: %@", allGivens);
    
    // assert that user givens wins in case of overlapping
    XCTAssertEqualObjects(@"hi", allGivens[kLanguageKey]);
}

@end
