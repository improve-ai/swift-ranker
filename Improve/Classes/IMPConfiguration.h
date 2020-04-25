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

/// The unique id for this user so that their events can be tracked
@property (copy, nonatomic) NSString *userId DEPRECATED_ATTRIBUTE;

/// The name of the project, required for remove model urls
@property (copy, nonatomic) NSString *projectName;

@property (copy, nonatomic) NSArray<NSString*> *modelNames;

/**
 The max age of cached models. Models, which are stale will be downloaded again
 on Improve signleton creation. The default value is 0.
 */
@property (assign, nonatomic) NSTimeInterval modelStaleAge;

/// This probability affects how often "variants" input is included to track report. Should be within [0, 1]. The default is 0.01.
@property (assign, nonatomic) double variantTrackProbability;

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                            projectName:(NSString *)projectName
                                 userId:(nullable NSString *)userId
                             modelNames:(NSArray<NSString*> *)modelNames;

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                            projectName:(NSString *)projectName
                             modelNames:(NSArray<NSString*> *)modelNames;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAPIKey:(NSString *)apiKey
                   projectName:(NSString *)projectName
                        userId:(nullable NSString *)userId
                    modelNames:(NSArray<NSString*> *)modelNames
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithAPIKey:(NSString *)apiKey
                   projectName:(NSString *)projectName
                    modelNames:(NSArray<NSString*> *)modelNames;

@end

NS_ASSUME_NONNULL_END
