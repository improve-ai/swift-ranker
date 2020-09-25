//
//  IMPModelConfiguration.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelConfiguration.h"

@implementation IMPModelConfiguration
- (instancetype) init
{
    self = [super init];
    if (!self) return nil;
    
    _autoTrackDecisions = TRUE;
    
    return self;
}

@end
