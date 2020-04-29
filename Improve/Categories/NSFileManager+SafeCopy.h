//
//  NSFileManager+SafeCopy.h
//  ImproveUnitTests
//
//  Created by Vladimir on 4/30/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (SafeCopy)

/// This will copy item if destination is empty or replace the destination item.
- (BOOL)safeCopyItemAtURL:(NSURL *)srcURL
                    toURL:(NSURL *)dstURL
                    error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
