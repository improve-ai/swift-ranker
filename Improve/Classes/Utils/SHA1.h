//
//  SHA1.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/12/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const NSUInteger kSHA1OutputStringLength;

NS_ASSUME_NONNULL_BEGIN

@interface SHA1 : NSObject

/**
 Encodes a string with SHA1 and returns 16-bit output.
 @param string A string to encode
 @returns A 16-bit number formatted to a NSString (40 chars). 
 */
+ (NSString *)encode:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
