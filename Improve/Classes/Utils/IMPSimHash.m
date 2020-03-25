//
//  IMPSimHash.m
//  ImproveUnitTests
//
//  Created by Vladimir on 3/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPSimHash.h"
#import "IMPMurmurHash.h"


@implementation IMPSimHash

+ (IMPSimHashOutput)transform:(NSSet<NSString*> *)strings
{
    IMPSimHashOutput output = {};

    for (NSString *str in strings)
    {
        uint32_t hash = [IMPMurmurHash hash32:str];

        uint32_t mask = 0x1;
        for (int i = 0; i < IMP_SIMHASH_SIZE; i++)
        {
            if ((hash & mask) != 0x0) {
                output.counters[i] += 1;
            } else {
                output.counters[i] -= 1;
            }
        }
    }

    return output;
}

@end
