//
//  SHA1.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/12/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "SHA1.h"
#import <CommonCrypto/CommonCrypto.h>

const NSUInteger kSHA1OutputStringLength = 40;

@implementation SHA1

+ (NSString *)encode:(NSString *)string
{
    const char *cString = [string UTF8String];
    unsigned char result[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(cString, (CC_LONG)strlen(cString), result);
    NSString *encodedString = [NSString  stringWithFormat:
                   @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   result[0], result[1], result[2], result[3], result[4],
                   result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11], result[12],
                   result[13], result[14], result[15],
                   result[16], result[17], result[18], result[19]
                   ];
    return encodedString;
}

@end
