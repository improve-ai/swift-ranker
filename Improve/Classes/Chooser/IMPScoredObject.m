//
//  IMPScoredObject.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPScoredObject.h"

@implementation IMPScoredObject

+ (instancetype)withScore:(double)score object:(id)object
{
    return [[self alloc] initWithScore:score object:object];
}

- (instancetype)initWithScore:(double)score object:(id)object
{
    self = [super init];
    if (self) {
        self.score = score;
        self.object = object;
    }
    return self;
}

@end
