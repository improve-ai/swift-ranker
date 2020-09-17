//
//  IMPCredential.m
//  ImproveUnitTests
//
//  Created by Vladimir on 9/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPCredential.h"

@implementation IMPCredential

+ (instancetype)credentialWithModelURL:(NSURL *)modelURL
                                apiKey:(NSString *)apiKey
{
    IMPCredential *credential = [[self alloc] init];
    credential.modelURL = modelURL;
    credential.apiKey = apiKey;
    return credential;
}

- (NSUInteger)hash
{
    return self.modelURL.hash ^ self.apiKey.hash;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:self.class]) {
        IMPCredential *other = object;
        return ([self.modelURL isEqual:other.modelURL]
                && [self.apiKey isEqualToString:other.apiKey]);
    } else {
        return false;
    }
}

#pragma mark NSCopying

- (id)copyWithZone:(nullable NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];

    if (copy) {
        [copy setModelURL:[self.modelURL copyWithZone:zone]];
        [copy setApiKey:[self.apiKey copyWithZone:zone]];
    }

    return copy;
}

@end
