//
//  IMPModelConfiguration.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelConfiguration.h"

@implementation IMPModelConfiguration

+ (IMPModelConfiguration *) configuration
{
    return [[IMPModelConfiguration alloc] init];
}

- (instancetype) init
{
    self = [super init];
    if (!self) return nil;
    
    _autoTrackChooseDecisions = TRUE;
    
    return self;
}

@end
