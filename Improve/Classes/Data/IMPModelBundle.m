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


@implementation IMPFolderModelBundle

- (instancetype)initWithModelName:(NSString *)modelName
                          rootURL:(NSURL *)rootFolderURL
{
    assert(modelName != nil);
    NSURL *folderURL = [rootFolderURL URLByAppendingPathComponent:modelName];

    NSURL *modelURL = [folderURL URLByAppendingPathComponent:@"model.mlmodelc"];

    NSURL *metadataURL = [folderURL URLByAppendingPathComponent:@"model.json"];

    self = [super initWithModelURL:modelURL metadataURL:metadataURL];
    if (self) {
        _modelName = modelName;
        _folderURL = folderURL;
    }
    return self;
}

@end
