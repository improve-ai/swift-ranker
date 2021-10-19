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
#import "IMPJSONUtils.h"
#import "IMPLogging.h"
#import "IMPDecisionModel.h"

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

+ (void)dumpScores:(NSArray<NSNumber *> *)scores andVariants:(NSArray *)variants {
    int LeadingCount = 10;
    int TrailingCount = 10;
    
    // sort variants by scores
    NSArray *sortedVariants = [IMPDecisionModel rank:variants withScores:scores];

    // sort scores
    NSArray *sortedScores = [scores sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]];
    
    if([scores count] <= (LeadingCount + TrailingCount)) {
        // dump all
        for(NSUInteger i = 0; i < [scores count]; ++i) {
            IMPLog("#%ld score: %@ variant: %@", i, sortedScores[i], [IMPJSONUtils jsonStringOrDerscriptionOf:sortedVariants[i]]);
        }
    } else {
        // dump top N scores and variants
        for(NSUInteger i = 0; i < LeadingCount; ++i) {
            IMPLog("#%ld score: %@ variant: %@", i, sortedScores[i], [IMPJSONUtils jsonStringOrDerscriptionOf:sortedVariants[i]]);
        }
        
        // dump bottom N scores and variants
        for(NSUInteger i = [scores count] - TrailingCount; i < [scores count]; ++i) {
            IMPLog("#%ld score: %@ variant: %@", i, sortedScores[i], [IMPJSONUtils jsonStringOrDerscriptionOf:sortedVariants[i]]);
        }
    }
}

@end
