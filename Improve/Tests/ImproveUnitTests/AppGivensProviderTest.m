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

@interface AppGivensProviderTest : XCTestCase

@end

@interface AppGivensProvider()

- (IMPDeviceInfo *)parseDeviceInfo:(NSString *)platform;

- (NSDecimalNumber *)improveVersion:(NSString *)version;

- (NSDecimalNumber *)rewardOfModel:(NSString *)modelName;

@end

@implementation AppGivensProviderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
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

- (void)testAddReward {
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    
    double accuracy = 0.000001;
    double reward = (double)arc4random() / UINT32_MAX;
    NSString *modelName = [[NSUUID UUID] UUIDString];
    XCTAssertEqualWithAccuracy(0, [[provider rewardOfModel:modelName] doubleValue], accuracy);
    [AppGivensProvider addReward:reward forModel:modelName];
    XCTAssertEqualWithAccuracy(reward, [[provider rewardOfModel:modelName] doubleValue], accuracy);
}

extern NSString *const kLanguageKey;
- (void)testOverlappingKeys {
    NSDictionary *givens = @{
       kLanguageKey : @"hi"
    };
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    NSDictionary *allGivens = [provider givensForModel:decisionModel givens:givens];
    
    NSLog(@"%@ = %@", kLanguageKey, allGivens[kLanguageKey]);
    
    XCTAssertEqual(@"hi", allGivens[kLanguageKey]);
}

extern NSString *const kSessionStartTimeKey;
extern NSString * const kSinceLastSessionStartKey;
// exclude since_last_session_start from givens when it's 0
- (void)testExclude_0_Since_Last_Session_Start {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kSessionStartTimeKey];
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello"];
    AppGivensProvider *provider = [[AppGivensProvider alloc] init];
    NSDictionary *allGivens = [provider givensForModel:decisionModel givens:@{}];
    
    XCTAssertEqual(18, [allGivens count]);
    XCTAssertNil(allGivens[kSinceLastSessionStartKey]);
}

@end
