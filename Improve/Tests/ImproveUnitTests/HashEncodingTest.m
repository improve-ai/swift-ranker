//
//  HashEncodingTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/22/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "XXHashUtils.h"
#include <sys/time.h>

@interface HashEncodingTest : XCTestCase

@end

@implementation HashEncodingTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testXXHash {
    XCTAssertEqualObjects(@"26c7827d889f6da3", [XXHashUtils encode:@"hello"]);
}

@end
