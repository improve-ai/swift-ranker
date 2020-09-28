//
//  IMPTracker.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPTracker.h"
#import "IMPLogging.h"

NSString * const kModelKey = @"model";
NSString * const kHistoryIdKey = @"history_id";
NSString * const kTimestampKey = @"timestamp";
NSString * const kMessageIdKey = @"message_id";
NSString * const kTypeKey = @"type";
NSString * const kVariantKey = @"variant";
NSString * const kContextKey = @"context";
NSString * const kRewardsKey = @"rewards";
NSString * const kVariantsCountKey = @"variants_count";
NSString * const kSampleVariantKey = @"sample_variant";
NSString * const kRewardKeyKey = @"reward_key";
NSString * const kMethodKey = @"method";

NSString * const kDecisionType = @"decision";
NSString * const kRewardsType = @"rewards";

NSString * const kChooseMethod = @"choose";
NSString * const kSortMethod = @"sort";

NSString * const kApiKeyHeader = @"x-api-key";

@import Security;

NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";

@interface IMPTracker ()
// Private vars

@property (strong, atomic) NSString *historyId;

@end


@implementation IMPTracker

- (instancetype) initWithConfiguration:(IMPModelConfiguration *)configuration;
{
    self = [super init];
    if (!self) return nil;
    
    _configuration = configuration;
    
    if (!configuration || !configuration.trackUrl) {
        IMPErrLog("configuration or trackUrl is nil, tracking disabled");
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _historyId = [defaults stringForKey:kHistoryIdDefaultsKey];
    if (!_historyId) {
        _historyId = [self generateHistoryId];
        [defaults setObject:_historyId forKey:kHistoryIdDefaultsKey];
    }

    return self;
}

- (NSString *) generateHistoryId {
    int historyIdSize = 32; // 256 bits
    SInt8 bytes[historyIdSize];
    int status = SecRandomCopyBytes(kSecRandomDefault, historyIdSize, bytes);
    if (status != errSecSuccess) {
        IMPErrLog("SecRandomCopyBytes failed, status: %d", status);
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBytes:bytes length:historyIdSize];
    NSString *historyId = [data base64EncodedStringWithOptions:0];
    return historyId;
}


- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey
             modelName:(NSString *) modelName
            completion:(nullable IMPTrackCompletion) completionHandler
{
    if (!self.configuration || !self.configuration.trackUrl) {
        return;
    }

    if (!variant) {
        IMPErrLog("Skipping trackDecision for nil variant. To track null values use [NSNull null]");
        if (completionHandler) completionHandler(nil);
        return;
    }

    // the rewardKey is never nil
    if (!rewardKey) {
        IMPLog("Using model name as rewardKey: %@", modelName);
        if (completionHandler) completionHandler(nil);
        rewardKey = modelName;
    }

    NSMutableDictionary *body = [@{ kTypeKey: kDecisionType,
                                    kVariantKey: variant,
                                    kModelKey: modelName,
                                    kRewardKeyKey: rewardKey } mutableCopy];

    if (context) {
        [body setObject:context forKey:kContextKey];
    }

    NSURL *trackUrl = [NSURL URLWithString:self.configuration.trackUrl];
    [self postImproveRequest:body url:trackUrl block:^(NSObject *result, NSError *error) {
        if (error) {
            IMPErrLog("Improve.track error: %@", error);
            IMPLog("trackDecision failed! model: %@, variant: %@, context: %@, rewardKey: %@", modelName, variant, context, rewardKey);
        } else {
            IMPLog("trackDecision succeed with model: %@, variant: %@, context: %@, rewardKey: %@", modelName, variant, context, rewardKey);
        }
        if (completionHandler) completionHandler(error);
    }];
}


- (void) addReward:(NSNumber *) reward
            forKey:(NSString *) rewardKey
        completion:(nullable IMPTrackCompletion) completionHandler
{
    if (rewardKey && reward) {
        [self addRewards:@{ rewardKey: reward } completion:completionHandler];
    } else {
        IMPErrLog("Skipping trackReward for nil rewardKey or reward");
        if (completionHandler) completionHandler(nil);
    }
}


- (void) addRewards:(NSDictionary<NSString *, NSNumber *> *) rewards
         completion:(nullable IMPTrackCompletion) completionHandler
{
    if (rewards) {
        IMPLog("Tracking rewards: %@", rewards);
        [self track:@{
            kTypeKey: kRewardsType,
            kRewardsKey: rewards
        }
         completion:^(NSError *error) {
            if (completionHandler) completionHandler(error);
        }];
    } else {
        IMPErrLog("Skipping trackRewards for nil rewards");
        if (completionHandler) completionHandler(nil);
    }
}

- (void) track:(NSDictionary *) body {
    [self track:body completion:nil];
}

- (void) track:(NSDictionary *)body completion:(nullable IMPTrackCompletion)completionBlock
{
    if (!self.configuration || !self.configuration.trackUrl) {
        return;
    }

    [self postImproveRequest:body
                         url:[NSURL URLWithString:self.configuration.trackUrl]
                       block:^
     (NSObject *result, NSError *error) {
        if (error) {
            IMPErrLog("Improve.track error: %@", error);
        }
        if (completionBlock) completionBlock(error);
    }];
}

/**
 Sends POST HTTP request to the sepcified url.

 Body values for kTimestampKey, kHistoryIdKey and kMessageIdKey are added autmatically. You can override them
 providing values in the body.
 */
- (void) postImproveRequest:(NSDictionary *) bodyValues url:(NSURL *) url block:(void (^)(NSObject *, NSError *)) block
{
    if (!self.historyId) {
        block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: @"_historyId cannot be nil"}]);
        return;
    }

    NSMutableDictionary *headers = [@{ @"Content-Type": @"application/json" } mutableCopy];
    
    if (self.configuration.trackApiKey) {
        [headers setObject:self.configuration.trackApiKey forKey:kApiKeyHeader];
    }

    NSString *dateStr = [self timestampFromDate:[NSDate date]];

    NSMutableDictionary *body = [@{
        kTimestampKey: dateStr,
        kHistoryIdKey: self.historyId,
        kMessageIdKey: [[NSUUID UUID] UUIDString]
    } mutableCopy];
    [body addEntriesFromDictionary:bodyValues];
    
    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        IMPLog("Data serialization error: %@\nbody: %@", err, body);
        block(nil, err);
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request
                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        if (!block) {
            return;
        }

        if (!error && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];

            if (statusCode >= 400) {
                NSMutableDictionary *userInfo = [[(NSHTTPURLResponse *) response allHeaderFields] mutableCopy];
                NSString *content = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                if (content) {
                    userInfo[NSLocalizedFailureReasonErrorKey] = content;
                }
                error = [NSError errorWithDomain:@"ai.improve" code:statusCode userInfo:userInfo];
            }
        }

        id jsonObject;

        if (!error) {
            // parse the NSData response
            // a parse error is a possibility
            jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        }

        if (error) { // transport, HTTP, or parse error
            block(nil, error);
        } else {
            // success!
            block(jsonObject, nil);
        }
    }];
    [dataTask resume];
}

/// Example: 2020-02-03T03:16:36.073Z
- (NSString *)timestampFromDate:(NSDate *)date
{
    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);

    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:date
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];

    return dateStr;
}


@end
