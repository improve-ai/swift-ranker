//
//  IMPModelMetadata.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelMetadata.h"
#import "IMPLogging.h"
#import "IMPJSONUtils.h"


@implementation IMPModelMetadata

- (instancetype)initWithDict:(NSDictionary *)json
{
    self = [super init];
    if (!self) return nil;

    _seed = [json[@"model_seed"] unsignedIntValue];
    _modelName = json[@"model"];

    return self;
}

- (nullable instancetype)initWithString:(NSString *)jsonString
{
    NSError *error;
    NSDictionary *jsonDict = [IMPJSONUtils objectFromString:jsonString];
    if (!jsonDict) {
        IMPErrLog("Json parse error: %@", error);
        return nil;
    }

    self = [self initWithDict:jsonDict];
    return self;
}

@end
