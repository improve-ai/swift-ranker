//
//  IMPCredential.h
//  ImproveUnitTests
//
//  Created by Vladimir on 9/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPCredential : NSObject

+ (instancetype)credentialWithModelURL:(NSString *)modelURL
                                apiKey:(NSString *)apiKey;

@property(nonatomic, copy) NSString *modelURL;

@property(nonatomic, copy) NSString *apiKey;

@end

NS_ASSUME_NONNULL_END
