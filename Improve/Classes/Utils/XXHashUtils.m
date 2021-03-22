//
//  XXHashUtils.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/22/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "XXHashUtils.h"
#import "xxhash.h"

const NSUInteger kXXHashOutputStringLength = 40;

@implementation XXHashUtils

+ (NSString *)encode:(NSString *)string{
    const char *input = [string UTF8String];
    uint64_t hash = XXH64(input, strlen(input), 0);
    return [self hash_to_feature_name:hash];
}

+ (NSString *)hash_to_feature_name:(uint64_t)hash{
    char buffer[17];
    sprintf(buffer, "%016llx", hash);
    return @(buffer);
}

@end
