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
    double u1 = drand48();
    double u2 = drand48();
    double f1 = sqrt(-2 * log(u1));
    double f2 = 2 * M_PI * u2;
    return f1 * cos(f2);
}


/**
 * Generate n = variants.count random (double) gaussian numbers
 * Sort the numbers descending and return the sorted list
 * The median value of the list is expected to have a score near zero
 */
+ (NSArray *)generateDescendingGaussians:(NSUInteger) count {
    srand48(time(0));
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; ++i){
        [arr addObject:[NSNumber numberWithDouble:[IMPUtils gaussianNumber]]];
    }
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 doubleValue] < [obj2 doubleValue];
    }];
    return [arr copy];
}

@end
