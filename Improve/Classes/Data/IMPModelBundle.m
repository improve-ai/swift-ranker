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

        NSError *err;
        NSDate *creationDate;
        if (![metadataURL getResourceValue:&creationDate
                                    forKey:NSURLCreationDateKey
                                     error:&err])
        {
            NSLog(@"-[%@ %@] error while reading date: %@", CLASS_S, CMD_S, err);
        }
        _creationDate = creationDate;
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@(modelURL: %@, metadataURL: %@)",
            NSStringFromClass(self.class),
            self.modelURL,
            self.metadataURL];
}

@end


@implementation IMPFolderModelBundle

- (instancetype)initWithModelName:(NSString *)modelName
                          rootURL:(NSURL *)rootFolderURL
{
    NSURL *folderURL = [rootFolderURL URLByAppendingPathComponent:self.modelName];

    NSURL *modelURL = [folderURL URLByAppendingPathComponent:modelName];
    modelURL = [folderURL URLByAppendingPathExtension:@"mlmodelc"];

    NSURL *metadataURL = [folderURL URLByAppendingPathComponent:modelName];
    metadataURL = [folderURL URLByAppendingPathExtension:@"json"];

    self = [super initWithModelURL:modelURL metadataURL:metadataURL];
    if (self) {
        _modelName = modelName;
        _folderURL = folderURL;
    }
    return self;
}

@end
