//
//  IMPTracker.m
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPTracker.h"
#import "IMPLogging.h"
#import "NSArray+Random.h"

@import Security;

static NSString * const kModelKey = @"model";
static NSString * const kHistoryIdKey = @"history_id";
static NSString * const kTimestampKey = @"timestamp";
static NSString * const kMessageIdKey = @"message_id";
static NSString * const kTypeKey = @"type";
static NSString * const kVariantKey = @"variant";
static NSString * const kContextKey = @"context";
static NSString * const kRewardsKey = @"rewards";
static NSString * const kVariantsCountKey = @"variants_count";
static NSString * const kVariantsKey = @"variants";
static NSString * const kSampleVariantKey = @"sample_variant";
static NSString * const kRewardKeyKey = @"reward_key";
static NSString * const kEventKey = @"event";
static NSString * const kPropertiesKey = @"properties";

static NSString * const kDecisionType = @"decision";
static NSString * const kRewardsType = @"rewards";
static NSString * const kEventType = @"event";

static NSString * const kApiKeyHeader = @"x-api-key";

static NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";

@interface IMPTracker ()
// Private vars

@property (strong, atomic) NSString *historyId;

@end


@implementation IMPTracker

- (instancetype) initWithTrackURL:(NSURL *) trackURL
{
    return [self initWithTrackURL:trackURL apiKey:nil];
}

- (instancetype) initWithTrackURL:(NSURL *) trackURL apiKey:(nullable NSString *) apiKey
{
    self = [super init];
    if (!self) return nil;
    
    _trackURL = trackURL;
    _apiKey = apiKey;
    
    if (!trackURL) {
        IMPErrLog("trackUrl is nil, tracking disabled");
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


/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 */
- (void) trackDecision:(id) variant
          fromVariants:(NSArray *) variants
             modelName:(NSString *) modelName
{
    [self trackDecision:variant fromVariants:variants modelName:modelName context:nil rewardKey:nil completion:nil];
}

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.

 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
*/
- (void) trackDecision:(id) variant
          fromVariants:(NSArray *) variants
             modelName:(NSString *) modelName
               context:(nullable NSDictionary *) context
{
    [self trackDecision:variant fromVariants:variants modelName:modelName context:context rewardKey:nil completion:nil];
}

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
*/
- (void) trackDecision:(id) variant
          fromVariants:(NSArray *) variants
             modelName:(NSString *) modelName
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey
{
    [self trackDecision:variant fromVariants:variants modelName:modelName context:context rewardKey:rewardKey completion:nil];
}

/**
 Track that a variant was chosen in order to train the system to learn what rewards it receives.
 @param variant The JSON encodeable chosen variant to track
 @param context The JSON encodeable context that the chosen variant is being used in and should be rewarded against.  It is okay for this to be different from the context that was used during choose or sort.
 @param rewardKey The rewardKey used to assign rewards to the chosen variant. If nil, rewardKey is set to the namespace.  trackRewards must also use this key to assign rewards to this chosen variant.
 @param completionHandler Called after sending the decision to the server.
 */
- (void) trackDecision:(id) variant
          fromVariants:(NSArray *) variants
             modelName:(NSString *) modelName
               context:(nullable NSDictionary *) context
             rewardKey:(nullable NSString *) rewardKey
            completion:(nullable IMPTrackCompletion) completionHandler;
{
    NSURL *trackURL = self.trackURL; // copy since atomic
    if (!trackURL) {
        return;
    }

    // TODO implement variants sampling
    
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

    if (variants && variants.count > 0)
    {
        body[kVariantsCountKey] = @(variants.count);

        if (drand48() > 1.0 / (double)variants.count)
        {
            id randomSample = variants.randomObject;
            body[kSampleVariantKey] = randomSample;
        }
        else
        {
            body[kVariantsKey] = variants;
        }
    }

    [self postImproveRequest:body url:trackURL block:^(NSObject *result, NSError *error) {
        if (error) {
            IMPErrLog("Improve.track error: %@", error);
        }
        if (completionHandler) completionHandler(error);
    }];
}

- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey
{
    [self addRewards:@{ rewardKey: reward } completion:nil];
}

- (void) addRewards:(NSDictionary *)rewards
{
    [self addRewards:rewards completion:nil];
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

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties {
    [self trackAnalyticsEvent:event properties:properties context:nil];
}

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context {

    NSMutableDictionary *body = [@{ kTypeKey: kEventType } mutableCopy];

    if (event) {
        [body setObject:event forKey:kEventKey];
    }
    if (properties) {
        [body setObject:properties forKey:kPropertiesKey];
    }
    if (context) {
        [body setObject:context forKey:kContextKey];
    }

    [self track:body];
}

- (void) track:(NSDictionary *) body {
    [self track:body completion:nil];
}

- (void) track:(NSDictionary *)body completion:(nullable IMPTrackCompletion)completionBlock
{
    NSURL *trackURL = self.trackURL; // copy since atomic
    if (!trackURL) {
        return;
    }

    [self postImproveRequest:body
                         url:trackURL
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
    
    NSString *trackApiKey = self.apiKey; // copy since atomic
    if (trackApiKey) {
        [headers setObject:trackApiKey forKey:kApiKeyHeader];
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
    
    IMPLog("POSTing %@", [[NSString alloc] initWithData:postData encoding:NSUTF8StringEncoding]);
    
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
