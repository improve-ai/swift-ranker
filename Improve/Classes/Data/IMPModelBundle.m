//
//  IMPModelBundle.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelBundle.h"
#import "IMPCommon.h"


@implementation IMPModelBundle

- (instancetype)initWithModelURL:(NSURL *)modelURL metadataURL:(NSURL* )metadataURL
{
    self = [super init];
    if (self) {
        _modelURL = modelURL;
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
            self.modelURL,
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
        NSLog(@"-[%@ %@] error while reading date: %@", CLASS_S, CMD_S, err);
        return nil;
    }
}

- (BOOL)isReachable {
    BOOL areExist = [self.modelURL checkResourceIsReachableAndReturnError:NULL]
        && [self.metadataURL checkResourceIsReachableAndReturnError:NULL];
    return areExist;
}

@end
