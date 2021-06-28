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
static NSString * const kGivenKey = @"given";
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
    if(self = [super init]) {
        _trackURL = trackURL;
        _apiKey = apiKey;
        _maxRunnersUp = 50;

        if (!trackURL) {
            IMPErrLog("trackUrl is nil, tracking disabled");
        }

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _historyId = [defaults stringForKey:kHistoryIdDefaultsKey];
        if (!_historyId) {
            _historyId = [[NSUUID UUID] UUIDString];
            [defaults setObject:_historyId forKey:kHistoryIdDefaultsKey];
        }
    }
    return self;
}

- (NSArray *)topRunnersUp:(NSArray *)ranked
{
    NSRange range = NSMakeRange(1, MIN(self.maxRunnersUp, ranked.count-1));
    return [ranked subarrayWithRange:range];
}

// By tracking with probability 1 / runnersUp.count we are
// tracking, on average, one runner up per decision
//
// variants.count - 1 is equal to the count of the all of the items that
// are worse than the best (all runners up)
- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount
{
    if (variantsCount <= 1 || self.maxRunnersUp == 0) {
        return NO;
    }
    return ((double)arc4random() / UINT32_MAX) < 1.0 / MIN(variantsCount - 1, self.maxRunnersUp);
}

- (void)track:(id)bestVariant variants:(NSArray *)variants given:(NSDictionary *)givens modelName:(NSString *)modelName variantsRankedAndTrackRunnersUp:(BOOL) variantsRankedAndTrackRunnersUp
{
    if ([modelName length] <= 0) {
        IMPErrLog("Improve.track error modelName is empty or nil");
        return;
    }
    
    NSMutableDictionary *body = [@{
        kTypeKey: kDecisionType,
        kModelKey: modelName,
        kCountKey: @(variants.count),
    } mutableCopy];
    
    [self setBestVariant:bestVariant dict:body];

    if (givens) {
        body[kGivenKey] = givens;
    }
    
    NSArray *runnersUp;
    if (variantsRankedAndTrackRunnersUp) {
        runnersUp = [self topRunnersUp:variants];
        body[kRunnersUpKey] = runnersUp;
    }

    id sampleVariant = [self sampleVariantOf:variants runnersUpCount:runnersUp.count];
    if(sampleVariant) {
        body[kSampleKey] = sampleVariant;
    }

    [self track:body];
}

// If there are no runners up, then sample is a random sample from
// variants with just best excluded.
//
// If there are runners up, then sample is a random sample from
// variants with best and runners up excluded.
//
// If there is only one variant, which is the best, then there is no sample.
//
// If there are no remaining variants after best and runners up, then
// there is no sample.
- (id)sampleVariantOf:(NSArray *)variants runnersUpCount:(NSUInteger)runnersUpCount {
    id sampleVariant = nil;
    NSUInteger samplesCount = variants.count - runnersUpCount - 1;
    if (samplesCount > 0) {
        NSRange range = NSMakeRange(runnersUpCount+1, samplesCount);
        NSArray *samples = [variants subarrayWithRange:range];
        sampleVariant = samples.randomObject;
    }
    return sampleVariant;
}

- (void)setBestVariant:(id)bestVariant dict:(NSMutableDictionary *)body {
    if (bestVariant) {
        body[kVariantKey] = bestVariant;
    } else {
        // This happens only in two cases
        // case 1: variants is empty
        // case 2: variants is nil
        body[kCountKey] = @1;
        body[kVariantKey] = [NSNull null];
    }
}

- (void)trackEvent:(NSString *)eventName
{
    [self trackEvent:eventName properties:nil];
}

- (void)trackEvent:(NSString *)eventName
        properties:(nullable NSDictionary *)properties
{
    NSMutableDictionary *body = [@{ kTypeKey: kEventType } mutableCopy];

    if (eventName) {
        [body setObject:eventName forKey:kEventKey];
    }
    
    if (properties) {
        [body setObject:properties forKey:kPropertiesKey];
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
        } else {
            IMPLog("Improve.track response: %@", result);
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
    
    
    NSError *err;
    NSData *postData;
    @try {
        postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    } @catch (NSException *e) {
        IMPLog("Variants or context not json encodable...This decision won't be tracked.");
        IMPLog("Data serialization error: %@\nbody: %@", e, body);
        block(nil, err);
        return ;
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
