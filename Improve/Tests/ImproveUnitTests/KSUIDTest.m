//
//  KSUIDTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 11/5/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+KSUID.h"
#import "ksuid.h"

@interface KSUIDTest : XCTestCase

@end

@implementation KSUIDTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testKSUID {
    NSString *ksuid = [NSString ksuidString];
    XCTAssertNotNil(ksuid);
    XCTAssertEqual(27, [ksuid length]);
    NSLog(@"ksuid: %@", ksuid);
    
    XCTAssertNotEqualObjects(ksuid, [NSString ksuidString]);
}

- (void)testMinTimestamp_Minus_1 {
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0x0
    uint8_t payload[KSUID_PAYLOAD_LENGTH] = {0};
    
    int result = ksuid_with_ts_and_payload(EPOCH_TIME - 1, payload, ksuid_buf);
    XCTAssertNotEqual(0, result);
}

- (void)testMinTimestamp_0 {
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0x0
    uint8_t payload[KSUID_PAYLOAD_LENGTH] = {0};
    
    int result = ksuid_with_ts_and_payload(EPOCH_TIME, payload, ksuid_buf);
    XCTAssertEqual(0, result);
    XCTAssertEqualObjects(@"000000000000000000000000000", [NSString stringWithUTF8String:ksuid_buf]);
}

- (void)testMinTimestamp_1 {
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0x0
    uint8_t payload[KSUID_PAYLOAD_LENGTH] = {0};
    
    int result = ksuid_with_ts_and_payload(EPOCH_TIME + 1, payload, ksuid_buf);
    XCTAssertEqual(0, result);
    XCTAssertEqualObjects(@"000007n42DGM5Tflk9n8mt7Fhc8", [NSString stringWithUTF8String:ksuid_buf]);
}

- (void)testMaxTimestamp_Minus_1 {
    NSLog(@"#%u", UINT32_MAX);
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0xff
    uint8_t payload[KSUID_PAYLOAD_LENGTH];
    for(int i = 0; i < KSUID_PAYLOAD_LENGTH; ++i) {
        payload[i] = 255;
    }
    
    uint64_t maxTimestamp = EPOCH_TIME + (uint64_t)UINT32_MAX - 1;
    int result = ksuid_with_ts_and_payload(maxTimestamp, payload, ksuid_buf);
    XCTAssertEqual(0, result);
    XCTAssertEqualObjects(@"aWgEPLxxrZOFaOlDVFHTB3ZiQON", [NSString stringWithUTF8String:ksuid_buf]);
}

- (void)testMaxTimestamp_0 {
    NSLog(@"#%u", UINT32_MAX);
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0xff
    uint8_t payload[KSUID_PAYLOAD_LENGTH];
    for(int i = 0; i < KSUID_PAYLOAD_LENGTH; ++i) {
        payload[i] = 255;
    }
    
    uint64_t maxTimestamp = EPOCH_TIME + (uint64_t)UINT32_MAX;
    int result = ksuid_with_ts_and_payload(maxTimestamp, payload, ksuid_buf);
    XCTAssertEqual(0, result);
    XCTAssertEqualObjects(@"aWgEPTl1tmebfsQzFP4bxwgy80V", [NSString stringWithUTF8String:ksuid_buf]);
}

- (void)testMaxTimestamp_1 {
    NSLog(@"#%u", UINT32_MAX);
    char ksuid_buf[KSUID_STRING_LENGTH + 1];
    
    // fill with 0xff
    uint8_t payload[KSUID_PAYLOAD_LENGTH];
    for(int i = 0; i < KSUID_PAYLOAD_LENGTH; ++i) {
        payload[i] = 255;
    }
    
    uint64_t maxTimestamp = EPOCH_TIME + (uint64_t)UINT32_MAX + 1;
    int result = ksuid_with_ts_and_payload(maxTimestamp, payload, ksuid_buf);
    XCTAssertNotEqual(0, result);
}


@end
