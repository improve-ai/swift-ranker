//
//  IMPSimHash.h
//  ImproveUnitTests
//
//  Created by Vladimir on 3/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IMP_SIMHASH_SIZE 32

typedef struct IMPSimHashOutput {
    int counters[IMP_SIMHASH_SIZE];
} IMPSimHashOutput;

NS_ASSUME_NONNULL_BEGIN

@interface IMPSimHash : NSObject

+ (IMPSimHashOutput)transform:(NSSet<NSString*> *)strings;

@end

NS_ASSUME_NONNULL_END
