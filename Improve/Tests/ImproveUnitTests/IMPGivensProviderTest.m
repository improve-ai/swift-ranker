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

@interface IMPAppGivensProvider()

- (IMPDeviceInfo *)parseDeviceInfo:(NSString *)platform;

- (double)versionToNumber:(NSString *)version;

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

@end
