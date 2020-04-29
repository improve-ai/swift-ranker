//
//  IMPConfiguration.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/23/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPConfiguration.h"
#import "IMPCommon.h"

@import Security;

#define USER_ID_KEY @"ai.improve.user_id"

#define HISTORY_ID_KEY @"ai.improve.history_id"

#define HISTORY_ID_SIZE 32

@implementation IMPConfiguration

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                            projectName:(NSString *)projectName
                                 userId:(nullable NSString *)userId
{
    id configuration = [[self alloc] initWithAPIKey:apiKey
                                        projectName:projectName
                                             userId:userId];
    return configuration;
}

+ (instancetype)configurationWithAPIKey:(NSString *)apiKey
                            projectName:(NSString *)projectName
{
    return [self configurationWithAPIKey:apiKey
                             projectName:projectName
                                  userId:nil];
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
                   projectName:(NSString *)projectName
                        userId:(nullable NSString *)userId
{
    self = [super init];
    if (!self) return nil;

    _apiKey = [apiKey copy];

    if (userId) {
        _userId = [userId copy];
    } else {
        _userId = [[NSUserDefaults standardUserDefaults] stringForKey:USER_ID_KEY];
        if (!_userId) {
            // create a UUID if one isn't provided
            _userId = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:_userId forKey:USER_ID_KEY];
        }
    }

    _modelStaleAge = 0.0;
    _variantTrackProbability = 0.01;
    _projectName = projectName;

    return self;
}

- (instancetype)initWithAPIKey:(NSString *)apiKey
                   projectName:(NSString *)projectName
{
    return [self initWithAPIKey:apiKey
                    projectName:projectName
                         userId:nil];
}

- (NSString *)historyId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *savedHistoryId = [defaults stringForKey:HISTORY_ID_KEY];
    if (savedHistoryId) { return savedHistoryId; }

    NSString *newHistoryId = [self generateHistoryId];
    [defaults setObject:newHistoryId forKey:HISTORY_ID_KEY];

    return newHistoryId;
}

- (NSString *)generateHistoryId {
    SInt8 bytes[HISTORY_ID_SIZE];
    int status = SecRandomCopyBytes(kSecRandomDefault, HISTORY_ID_SIZE, bytes);
    if (status != errSecSuccess) {
        NSLog(@"-[%@ %@]: SecRandomCopyBytes failed, status: %d", CLASS_S, CMD_S, status);

        // Backup to ensure nonempty bytes
        arc4random_buf(bytes, HISTORY_ID_SIZE);
    }
    NSData *data = [[NSData alloc] initWithBytes:bytes length:HISTORY_ID_SIZE];
    NSString *historyId = [data base64EncodedStringWithOptions:0];
    return historyId;
}

// For test cases
- (int)historyIdSize {
    return HISTORY_ID_SIZE;
}

- (NSURL *)remoteModelsArchiveURL {
    // Just a stub for test!!! Replace it!!
    NSString *path = @"https://d2pq40dxlsc486.cloudfront.net/myproject/model.tar.gz";
    return [NSURL URLWithString:path];
}
@end
