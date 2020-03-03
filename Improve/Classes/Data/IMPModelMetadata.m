//
//  IMPModelMetadata.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelMetadata.h"
#import "IMPCommon.h"

@implementation IMPModelMetadata

+ (instancetype)metadataWithURL:(NSURL *)url {
    return [[self alloc] initWithURL:url];
}

- (instancetype)initWithURL:(NSURL *)url
{
    self = [super init];
    if (!self) return nil;

    NSError *error;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (!data) {
        NSLog(@"-[%@ %@] data reading error: %@", CLASS_S, CMD_S, error);
        return nil;
    }
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!json) {
        NSLog(@"-[%@ %@] json parse error: %@", CLASS_S, CMD_S, error);
        return nil;
    }

    _numberOfFeatures = [json[@"hashed_feature_count"] integerValue];
    _hashPrefix = json[@"feature_hash_prefix"];
    _modelId = json[@"model_id"];

    return self;
}

@end
