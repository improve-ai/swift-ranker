//
//  NSFileManager+SafeCopy.m
//  ImproveUnitTests
//
//  Created by Vladimir on 4/30/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "NSFileManager+SafeCopy.h"

@implementation NSFileManager (SafeCopy)

- (BOOL)safeCopyItemAtURL:(NSURL *)srcURL
                    toURL:(NSURL *)dstURL
                    error:(NSError **)error
{
    if ([self fileExistsAtPath:dstURL.path]) {
        if (![self replaceItemAtURL:dstURL withItemAtURL:srcURL backupItemName:nil options:0 resultingItemURL:nil error:error]) {
            return false;
        }
    } else {
        if (![self copyItemAtURL:srcURL toURL:dstURL error:error]) {
            return false;
        }
    }
    return true;
}

@end
