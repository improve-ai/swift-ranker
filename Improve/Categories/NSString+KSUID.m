//
//  NSString+KSUID.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 11/5/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "NSString+KSUID.h"
#import "ksuid.h"

@implementation NSString (KSUID)

+ (NSString *)ksuidString {
    char buf[KSUID_STRING_LENGTH+1] = {0};
    if(ksuid(buf)) {
        return nil;
    }
    return [NSString stringWithUTF8String:buf];
}

@end
