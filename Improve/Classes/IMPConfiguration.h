//
//  IMPConfiguration.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/23/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPConfiguration : NSObject

/// The improve.ai api key
@property (copy, nonatomic) NSString *apiKey;

/// A unique id which is randomly generated and preserved across app sessions.
@property (readonly, nonatomic) NSString *historyId;

// TODO:
@property (readonly, nonatomic) NSURL *remoteModelsArchiveURL;

/**
 The max age of cached models. Models, which are stale will be downloaded again
 on Improve signleton creation. The default value is 0.
 */
@property (assign, nonatomic) NSTimeInterval modelStaleAge;

/// This probability affects how often "variants" input is included to track report. Should be within [0, 1]. The default is 0.01.
@property (assign, nonatomic) double variantTrackProbability;

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAPIKey:(NSString *)apiKey
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
