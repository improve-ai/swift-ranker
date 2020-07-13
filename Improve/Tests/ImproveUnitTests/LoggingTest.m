//
//  LoggingTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 7/12/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestUtils.h"


@interface LoggingTest : XCTestCase

@end

@implementation LoggingTest

- (void)testDebugLog {
    NSNumber *numb = @5;
    NSString *str = @"abc";
    double fraction = 0.005;
    IMPLog("Number is: %@, string is: %@, fraction is: %f", numb, str, fraction);
}

- (void)testErrorLog {
    NSString *str = @"Critical error!";
    NSString *errMsg = @"incorrect snack";
    NSError *err = [NSError errorWithDomain:@"ai.improve.LoggingTest"
                                       code:-100
                                   userInfo:@{NSLocalizedDescriptionKey: errMsg}];
    IMPErrLog("String: %@, error: %@", str, err);
}


@end
