//
//  IMPConfiguration.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/23/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"

@implementation IMPConfiguration

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                                 userId:(nullable NSString *)userId
                              modelName:(NSString *)modelName
{
  id configuration = [[self alloc] initWithAPIKey:apiKey
                                           userId:userId
                                        modelName:modelName];
  return configuration;
}

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                              modelName:(NSString *)modelName
{
  return [self configurationWithAPIKey:apiKey modelName:modelName];
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
                        userId:(nullable NSString *)userId
                     modelName:(NSString *)modelName
{
  self = [super init];
  if (!self) return nil;

  _apiKey = [apiKey copy];
  _userId = [userId copy];
  _modelName = [modelName copy];

  return self;
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
                     modelName:(NSString *)modelName
{
  return [self initWithAPIKey:apiKey userId:nil modelName:modelName];
}

- (NSURL *)modelURL {
  // TODO: It's just a stab, actual implementation pending.
  NSString *endpoint = @"https://api.improve.ai/v3/models";
  NSString *path = [NSString stringWithFormat:@"%@/%@.tar.gz", endpoint, self.modelName];
  NSURL *url = [NSURL URLWithString:path];
  return url;
}

@end
