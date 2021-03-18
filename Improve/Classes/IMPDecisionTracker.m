//
//  IMPDecisionTracker.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionTracker.h"
#import "IMPDecision.h"
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
static NSString * const kSampleKey = @"sample";
static NSString * const kEventKey = @"event";
static NSString * const kPropertiesKey = @"properties";
static NSString * const kCountKey = @"count";
static NSString * const kRunnersUpKey = @"runners_up";

static NSString * const kDecisionType = @"decision";
static NSString * const kEventType = @"event";

static NSString * const kApiKeyHeader = @"x-api-key";

static NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";


@interface IMPDecisionTracker ()
// Private vars

@property (strong, atomic) NSString *historyId;

@end

@implementation IMPDecisionTracker

- (instancetype)initWithTrackURL:(NSURL *)trackURL
{
    return [self initWithTrackURL:trackURL apiKey:nil];
}

- (instancetype)initWithTrackURL:(NSURL *)trackURL apiKey:(nullable NSString *)apiKey
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

- (NSArray *)topRunnersUp:(NSArray *)ranked
{
    NSRange range = NSMakeRange(0, MIN(self.maxRunnersUp, ranked.count));
    return [ranked subarrayWithRange:range];
}

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount
{
    return drand48() < 1.0 / MIN(variantsCount - 1, self.maxRunnersUp);
}

- (id)track:(IMPDecision *)decision runnersUp:(NSArray *)runnersUp
{
    BOOL shouldTrackRunnersUp = decision.shouldTrackRunnersUp;

    NSMutableDictionary *body = [@{
        kTypeKey: kDecisionType,
        kModelKey: decision.modelName,
        kCountKey: @(decision.variants.count),
        kContextKey: decision.givens
    } mutableCopy];

    NSArray *runnersUp = nil;
    if (shouldTrackRunnersUp) {
        // Runners up should be calculated before `best` in order to prevent extra work
        // `topRunnersUp` require calculation of `ranked`, the results
        // may be used to calculate `best`.
        // Calling just `best` without tracking will perform reservouir sampling,
        // which is faster than ranking.
        runnersUp = decision.topRunnersUp;
        body[kRunnersUpKey] = runnersUp;
    }

    // Calculate `best` after `trackRunnersUp`
    body[kVariantKey] = decision.best;

    // If runnersUp is nil `runnersUp.count` will return 0.
    NSInteger trackedVariantsCount = 1 + runnersUp.count;
    BOOL samplesCount = decision.variants.count - trackedVariantsCount;
    if (samplesCount > 0)
    {
        NSRange range = NSMakeRange(trackedVariantsCount,
                                    decision.ranked.count);
        NSArray *samples = [decision.ranked subarrayWithRange:range];
        id sampleVariant = samples.randomObject;
        body[kSampleKey] = sampleVariant;
    }

    [self track:body];

    return decision.best;
}

- (void)trackEvent:(NSString *)event
{
    [self trackEvent:event properties:nil];
}

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties
{
    [self trackEvent:event properties:properties context:nil];
}

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties
           context:(nullable NSDictionary *)context
{
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

- (void)track:(NSDictionary *)body
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
