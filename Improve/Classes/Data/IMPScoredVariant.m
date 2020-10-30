//
//  IMPScoredVariant.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/27/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPScoredVariant.h"

@implementation IMPScoredVariant

+ (instancetype)withScore:(double)score variant:(id)object
{
    return [[self alloc] initWithScore:score variant:object];
}

- (instancetype)initWithScore:(double)score variant:(id)object
{
    self = [super init];
    if (self) {
        self.score = score;
        self.variant = object;
    }
    return self;
}

@end
