//
//  IMPModelBundle.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelBundle.h"
#import "IMPLogging.h"


@implementation IMPModelBundle
@synthesize metadata = _metadata;

- (instancetype)initWithModelURL:(NSURL *)compiledModelURL metadataURL:(NSURL* )metadataURL
{
    self = [super init];
    if (self) {
        _compiledModelURL = compiledModelURL;
        _metadataURL = metadataURL;
    }
    return self;
}

- (instancetype)initWithDirectoryURL:(NSURL *)dirURL modelName:(NSString *)modelName
{
    assert(modelName != nil);

    NSString *modelFileName = [NSString stringWithFormat:@"%@.mlmodelc", modelName];
    NSURL *modelURL = [dirURL URLByAppendingPathComponent:modelFileName];

    NSString *metaFileName = [NSString stringWithFormat:@"%@.json", modelName];
    NSURL *metadataURL = [dirURL URLByAppendingPathComponent:metaFileName];

    self = [self initWithModelURL:modelURL metadataURL:metadataURL];
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(modelURL: %@, metadataURL: %@)",
            NSStringFromClass(self.class),
            self.compiledModelURL,
            self.metadataURL];
}

- (NSDate *)creationDate {
    NSError *err;
    NSDate *creationDate;
    if ([self.metadataURL getResourceValue:&creationDate
                                    forKey:NSURLCreationDateKey
                                     error:&err])
    {
        return creationDate;
    }
    else
    {
        IMPErrLog("Error while reading date: %@", err);
        return nil;
    }
}

- (BOOL)isReachable {
    NSError *error;
    if (![self.compiledModelURL checkResourceIsReachableAndReturnError:&error]) {
        IMPLog("Compiled model file is missing at: %@ error: %@", self.compiledModelURL, error);
        return false;
    }
    if (![self.metadataURL checkResourceIsReachableAndReturnError:&error]) {
        IMPLog("Metadata file is missing at: %@ error: %@", self.metadataURL, error);
        return false;
    }
    return true;
}

- (IMPModelMetadata *)metadata {
    if (_metadata) return _metadata;

    _metadata = [IMPModelMetadata metadataWithURL:self.metadataURL];
    return _metadata;
}

@end
