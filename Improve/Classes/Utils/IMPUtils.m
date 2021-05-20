//
//  IMPUtils.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/23/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

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

@end
