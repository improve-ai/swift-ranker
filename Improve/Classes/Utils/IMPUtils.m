//
//  IMPUtils.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/23/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <sys/sysctl.h>
#import <sys/types.h>

#import "IMPUtils.h"

@implementation IMPUtils

// Source: https://stackoverflow.com/a/12948538/3050403
+ (double)gaussianNumber{
    double u1 = (double)arc4random() / UINT32_MAX;
    double u2 = (double)arc4random() / UINT32_MAX;
    double f1 = sqrt(-2 * log(u1));
    double f2 = 2 * M_PI * u2;
    return f1 * cos(f2);
}

+ (NSString *)getPlatformString {
#if !TARGET_OS_OSX
    const char *sysctl_name = "hw.machine";
#else
    const char *sysctl_name = "hw.model";
#endif
    size_t size;
    sysctlbyname(sysctl_name, NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname(sysctl_name, machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

@end
