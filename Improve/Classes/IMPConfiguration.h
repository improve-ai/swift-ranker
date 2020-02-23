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

/// The unique id for this user so that their events can be tracked
@property (copy, nonatomic) NSString *userId;

@property (copy, nonatomic) NSString *modelName;

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                                 userId:(nullable NSString *)userId
                              modelName:(NSString *)modelName;

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                              modelName:(NSString *)modelName;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithAPIKey:(NSString *)apiKey
                        userId:(nullable NSString *)userId
                     modelName:(NSString *)modelName
NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithAPIKey:(NSString *)apiKey
                     modelName:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END
