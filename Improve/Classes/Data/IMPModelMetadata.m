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
        IMPErrLog("Data reading error: %@", error);
        return nil;
    }
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (!json) {
        IMPErrLog("Json parse error: %@", error);
        return nil;
    }

    _numberOfFeatures = [json[@"hashed_feature_count"] integerValue];
    _lookupTable = json[@"table"];
    _seed = [json[@"model_seed"] unsignedIntValue];
    _namespaces = json[@"namespaces"];

    return self;
}

@end
