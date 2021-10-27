//
//  AppGivensProviderTest.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 10/28/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AppGivensProvider.h"

@interface AppGivensProviderTest : XCTestCase

@end

@implementation AppGivensProviderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAppGivensProvider {
    NSString *modelName = @"hello";
    AppGivensProvider *appGivensProvider = [[AppGivensProvider alloc] init];
    NSDictionary *givens = [appGivensProvider givensForModel:modelName];
    NSLog(@"app givens: %@", givens);
    
    // nil carrier excluded from the givens
    XCTAssertEqual(19, [givens count]);
}

@end
