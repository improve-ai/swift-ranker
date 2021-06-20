//
//  IMPGivensProviderTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 6/11/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPAppGivensProvider.h"
#import "TestUtils.h"
#import "IMPDecisionModel.h"
#import "IMPDecision.h"

static NSString * const kDefaultsDecisionCountKey = @"ai.improve.decision_count";

static NSString * const kDefaultsSessionCountKey = @"ai.improve.session_count";

static NSString * const kBornTimeKey = @"ai.improve.born_time";

@interface IMPAppGivensProvider()

- (IMPDeviceInfo *)parseDeviceInfo:(NSString *)platform;

- (double)versionToNumber:(NSString *)version;

- (double)sinceSessionStart;

- (double)sinceLastSessionStart;

- (double)sinceBorn;

- (NSUInteger)sessionCount;

- (NSUInteger)decisionCount;

- (NSDictionary *)getGivens;

@end

@interface IMPGivensProviderTest : XCTestCase

@end

@implementation IMPGivensProviderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testGetAppGivens {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    
    NSDictionary *givens = [givensProvider getGivens];
    for(NSString *key in [givens allKeys]) {
      NSLog(@"givens: %@=%@", key, [givens objectForKey:key]);
    }
}

- (void)testParseDeviceInfo {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    IMPDeviceInfo *deviceInfo = [givensProvider parseDeviceInfo:@"iPad7,12"];
    XCTAssertEqualObjects(deviceInfo.model, @"iPad");
    XCTAssertEqual(deviceInfo.version, 7012);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"iPhone12,8"];
    XCTAssertEqualObjects(deviceInfo.model, @"iPhone");
    XCTAssertEqual(deviceInfo.version, 12008);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"iPhone"];
    XCTAssertEqualObjects(deviceInfo.model, @"iPhone");
    XCTAssertEqual(deviceInfo.version, 0);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"12,8"];
    XCTAssertEqualObjects(deviceInfo.model, @"12,8");
    XCTAssertEqual(deviceInfo.version, 0);
    
    NSString *platform = nil;
    deviceInfo = [givensProvider parseDeviceInfo:platform];
    XCTAssertEqualObjects(deviceInfo.model, @"unknown");
    XCTAssertEqual(deviceInfo.version, 0);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"i386"];
    XCTAssertEqualObjects(deviceInfo.model, @"Simulator");
    XCTAssertEqual(deviceInfo.version, 0);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"x86_64"];
    XCTAssertEqualObjects(deviceInfo.model, @"Simulator");
    XCTAssertEqual(deviceInfo.version, 0);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"iPhone 12,8"];
    XCTAssertEqualObjects(deviceInfo.model, @"iPhone");
    XCTAssertEqual(deviceInfo.version, 12008);
    
    deviceInfo = [givensProvider parseDeviceInfo:@"iPhone *,*"];
    XCTAssertEqualObjects(deviceInfo.model, @"iPhone");
    XCTAssertEqual(deviceInfo.version, 0);
}

- (void)testVersionToNumber {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    double version = [givensProvider versionToNumber:@"6.1.123"];
    XCTAssertEqual(version, 6001.123);
    
    version = [givensProvider versionToNumber:@"6.1"];
    XCTAssertEqual(version, 6001);
    
    version = [givensProvider versionToNumber:@"6"];
    XCTAssertEqual(version, 6000);
}

- (void)testSessionCountFirst {
    // remove previous defaults
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultsSessionCountKey];
    
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    XCTAssertEqual(0, [givensProvider sessionCount]);
    
    IMPAppGivensProvider *givensProvider2 = [[IMPAppGivensProvider alloc] init];
    XCTAssertEqual(0, [givensProvider2 sessionCount]);
}

// testSessionCountSecond must be run after testSessionCountFirst in a different session, otherwise
// they would be considered as one session and testSessionCountSecond would fail.
- (void)testSessionCountSecond {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    XCTAssertEqual(1, [givensProvider sessionCount]);
    NSLog(@"testSessionCountB");
}

- (void)testDecisionCount {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    NSUInteger decisionCount = [givensProvider decisionCount];
    
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSURL *url = [[TestUtils bundle] URLForResource:@"TestModel"
                                      withExtension:@"mlmodelc"];
    IMPDecisionModel *decisionModel = [IMPDecisionModel load:url error:nil];
    [[[decisionModel addGivensProvider:[IMPAppGivensProvider new]] chooseFrom:variants] get];
    
    XCTAssertEqual(decisionCount+1, [givensProvider decisionCount]);
}

- (void)testFirstDecisionCount {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kDefaultsDecisionCountKey];
    
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    XCTAssertEqual(0, [givensProvider decisionCount]);
}

// This test case should be run individually; otherwise it might fail.
- (void)testSinceSessionStart {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        double t = [givensProvider sinceSessionStart];
        XCTAssertEqualWithAccuracy(t, 3.0, 0.1);
        NSLog(@"sinceSessionStart: %lf", t);
        [ex fulfill];
    });
    [self waitForExpectations:@[ex] timeout:10];
}

- (void)testSinceBorn {
    // remove born time
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kBornTimeKey];
    
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    XCTestExpectation *ex = [[XCTestExpectation alloc] initWithDescription:@"Waiting for model creation"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        double t = [givensProvider sinceBorn];
        XCTAssertEqualWithAccuracy(t, 3.0, 0.1);
        NSLog(@"sinceBorn: %lf", t);
        [ex fulfill];
    });
    [self waitForExpectations:@[ex] timeout:10];
}

// IMPAppGivensProvider instances in one test case are in the same session
// I don't know how to unit test this one...
// Run it twice manually??
- (void)testSinceLastSessionStart {
    IMPAppGivensProvider *givensProvider = [[IMPAppGivensProvider alloc] init];
    double t = [givensProvider sinceLastSessionStart];
    NSLog(@"sinceLastSessionStart: %lf", t);
}

@end
