//
//  IMPModelManager.m
//  ImproveUnitTests
//
//  Created by Vladimir on 9/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPModelManager.h"
#import "IMPModelDownloader.h"
#import "IMPLogging.h"
#import "Constants.h"

NSNotificationName const IMPModelManagerDidLoadNotification = @"IMPModelManagerDidLoadNotification";

/// How soon model downloading will be retried in case of error.
const NSTimeInterval kRetryInterval = 30.0;

@interface IMPModelManager ()

@property(nonatomic, strong) NSMutableArray<IMPModelBundle*> *_models;

/// Credentials of the downloaded models.
@property(nonatomic, strong) NSMutableSet<IMPCredential*> *modelCredentials;

@property(nonatomic, strong) NSMutableDictionary<IMPCredential*, IMPModelDownloader*> *activeDownloaders;

@end


@implementation IMPModelManager

+ (instancetype)sharedManager
{
    static IMPModelManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[[self class] alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        __models = [NSMutableArray new];
        _maxModelsStaleAge = 604800.0;
    }
    return self;
}

- (NSArray<IMPModelBundle *> *)models {
    return self._models;
}

- (void)addModelWithCredential:(IMPCredential *)credential
{
    IMPLog("Initializing model loading with credential: %@...", credential);

    if ([self.modelCredentials containsObject:credential])
    {
        IMPLog("Model is already loaded. Exit.");
        return;
    }

    if (self.activeDownloaders[credential] != nil)
    {
        IMPLog("Model is already added and is being downloaded. Exit.");
        return;
    }

    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:credential.modelURL];
    self.activeDownloaders[credential] = downloader;

    IMPLog("Checking for cached models...");
    if (downloader.cachedModelAge < self.maxModelsStaleAge) {
        // Load models from cache
        IMPLog("Found cached models. Finished.");
        IMPModelBundle *cachedModel = downloader.cachedModelBundle;
        if (cachedModel) {
            [self._models addObject:cachedModel];
            [self.modelCredentials addObject:credential];

            [self notifyDidLoadModel:cachedModel];
        }
        return;
    }

    // Load remote models
    IMPLog("No cached models. Start downloading...");
    downloader.headers = @{kApiKeyHeader: credential.apiKey};
    [self loadWithDownloader:downloader credential:credential];
}

- (void)loadWithDownloader:(IMPModelDownloader *)downloader
                credential:(IMPCredential *)credential
{
    IMPLog("Loading model for credential: %@", credential);
    __weak IMPModelManager *weakSelf = self;
    [downloader loadWithCompletion:^(IMPModelBundle *bundle, NSError *error) {
        if (error) {
            IMPErrLog("Failed to load models: %@", error);

            // Reload
            IMPLog("Will retry after %g sec", kRetryInterval);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                IMPLog("Retrying...");
                [weakSelf loadWithDownloader:downloader credential:credential];
            });
        } else if (bundle) {
            IMPLog("Model loaded.");
            [weakSelf.modelCredentials addObject:credential];
            [weakSelf._models addObject:bundle];
            [weakSelf.activeDownloaders removeObjectForKey:credential];

            [weakSelf notifyDidLoadModel:bundle];
        }
    }];
}

- (IMPModelBundle *)modelForNamespace:(NSString *)namespaceStr
{
    for (IMPModelBundle *modelBundle in self.models)
    {
        if ([modelBundle.namespaces containsObject:namespaceStr])
        {
            return modelBundle;
        }
    }
    return nil;
}

- (void)notifyDidLoadModel:(IMPModelBundle *)model
{
    [[NSNotificationCenter defaultCenter] postNotificationName:IMPModelManagerDidLoadNotification object:self userInfo:@{@"model_bundle": model}];
}

@end
