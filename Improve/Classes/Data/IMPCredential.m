//
//  IMPCredential.m
//  ImproveUnitTests
//
//  Created by Vladimir on 9/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPCredential.h"

@implementation IMPCredential

+ (instancetype)credentialWithModelURL:(NSString *)modelURL
                                apiKey:(NSString *)apiKey
{
    IMPCredential *credential = [[self alloc] init];
    credential.modelURL = modelURL;
    credential.apiKey = apiKey;
    return credential;
}

@end
