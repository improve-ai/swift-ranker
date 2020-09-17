//
//  IMPModelManager.h
//  ImproveUnitTests
//
//  Created by Vladimir on 9/11/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPCredential.h"

@class IMPModelBundle;

NS_ASSUME_NONNULL_BEGIN

/**
 Posted when one of the models is downloaded or restored from the cache.
 User info: "model_bundle" - the downloaded IMPModelBundle.
 */
extern NSNotificationName const IMPModelManagerDidLoadNotification;

@interface IMPModelManager : NSObject 

/**
 Max stale age of the cached models. If the cached models has expired, the new ones will be requested soon.
 The default value is 604800 (1 week).
 */
@property (atomic, assign) NSTimeInterval maxModelsStaleAge;

+ (instancetype)sharedManager;

- (NSArray<IMPModelBundle*> *)models;

- (void)addModelWithCredential:(IMPCredential *)credential;

- (nullable IMPModelBundle *)modelForNamespace:(NSString *)namespaceStr;

@end

NS_ASSUME_NONNULL_END
