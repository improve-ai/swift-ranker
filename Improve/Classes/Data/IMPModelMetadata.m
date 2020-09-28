//
//  IMPModelMetadata.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelMetadata.h"
#import "IMPLogging.h"

@implementation IMPModelMetadata

- (nullable instancetype)initWithDict:(NSDictionary *)json
{
    self = [super init];
    if (!self) return nil;

    _numberOfFeatures = [json[@"hashed_feature_count"] integerValue];
    _lookupTable = json[@"table"];
    _seed = [json[@"model_seed"] unsignedIntValue];
    _model = json[@"model"];

    return self;
}

@end
