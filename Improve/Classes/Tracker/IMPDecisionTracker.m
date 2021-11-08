//
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import "IMPDecisionTracker.h"
#import "IMPDecision.h"
#import "IMPLogging.h"
#import "NSArray+Random.h"
#import "NSString+KSUID.h"

@import Security;

static NSString * const kModelKey = @"model";
static NSString * const kHistoryIdKey = @"history_id";
static NSString * const kTimestampKey = @"timestamp";
static NSString * const kMessageIdKey = @"message_id";
static NSString * const kTypeKey = @"type";
static NSString * const kVariantKey = @"variant";
static NSString * const kGivensKey = @"givens";
static NSString * const kSampleKey = @"sample";
static NSString * const kEventKey = @"event";
static NSString * const kPropertiesKey = @"properties";
static NSString * const kValueKey = @"value";
static NSString * const kCountKey = @"count";
static NSString * const kRunnersUpKey = @"runners_up";
static NSString * const kDecisionIdKey = @"decision_id";

static NSString * const kDecisionType = @"decision";
static NSString * const kEventType = @"event";

static NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";
static NSString * const kLastDecisionIdKey = @"ai.improve.last_decision-%@";


@interface IMPDecisionTracker ()
// Private vars

@property (strong, atomic) NSString *historyId;

@end

@implementation IMPDecisionTracker

- (instancetype)initWithTrackURL:(NSURL *)trackURL
{
    if(self = [super init]) {
        _trackURL = trackURL;
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
    return ((double)arc4random() / UINT32_MAX) <= 1.0 / MIN(variantsCount - 1, self.maxRunnersUp);
}

- (void)track:(id)bestVariant variants:(NSArray *)variants given:(NSDictionary *)givens modelName:(NSString *)modelName variantsRankedAndTrackRunnersUp:(BOOL) variantsRankedAndTrackRunnersUp
{
    if ([modelName length] <= 0) {
        IMPErrLog("Improve.track error modelName is empty or nil");
        return;
    }
    
    if(bestVariant != nil && [variants indexOfObject:bestVariant] == NSNotFound) {
        IMPErrLog("bestVariant must be included in variants");
        return ;
    }
    
    // create and persist decisionId
    NSString *decisionId = [self createAndPersistDecisionIdForModel:modelName];
    if(decisionId == nil) {
        IMPErrLog("decisionId generated is nil");
        return ;
    }
    
    NSMutableDictionary *body = [@{
        kTypeKey: kDecisionType,
        kModelKey: modelName,
        kDecisionIdKey: decisionId
    } mutableCopy];
    
    [self setBestVariant:bestVariant dict:body];
    
    [self setCount:variants dict:body];

    if (givens) {
        body[kGivensKey] = givens;
    }
    
    NSArray *runnersUp;
    if (variantsRankedAndTrackRunnersUp) {
        runnersUp = [self topRunnersUp:variants];
        body[kRunnersUpKey] = runnersUp;
    }

    id sampleVariant = [self sampleVariantOf:variants runnersUpCount:runnersUp.count ranked:variantsRankedAndTrackRunnersUp bestVariant:bestVariant];
    if(sampleVariant) {
        body[kSampleKey] = sampleVariant;
    }

    [self track:body];
}

/**
 * @param variants all variants
 * @param runnersUpCount number of runners_up variants
 * @param ranked Yes when variants is ranked with the first variant being the best; otherwise, the best variant
 * could be any one of the variants
 * If there are no runners up, then sample is a random sample from variants with just best excluded.
 * If there are runners up, then sample is a random sample from variants with best and runners up excluded.
 * If there is only one variant, which is the best, then there is no sample.
 * If there are no remaining variants after best and runners up, then there is no sample.
 * @return nil when there's no sample variant
 */
- (id)sampleVariantOf:(NSArray *)variants runnersUpCount:(NSUInteger)runnersUpCount ranked:(BOOL)ranked bestVariant:(id)bestVariant {
    if(bestVariant == nil) {
        return nil;
    }
    
    NSUInteger samplesCount = variants.count - runnersUpCount - 1;
    if(samplesCount <= 0) {
        return nil;
    }
    
    if(ranked) {
        NSRange range = NSMakeRange(runnersUpCount+1, samplesCount);
        NSArray *samples = [variants subarrayWithRange:range];
        return samples.randomObject;
    } else {
        // variants is not ranked and there is no runners-up
        NSUInteger indexOfBestVariant = [variants indexOfObject:bestVariant];
        while (true) {
            NSUInteger randomIdx = arc4random_uniform((uint32_t)variants.count);
            if(randomIdx != indexOfBestVariant) {
                return [variants objectAtIndex:randomIdx];
            }
        }
    }
}

- (void)setBestVariant:(id)bestVariant dict:(NSMutableDictionary *)body {
    if (bestVariant) {
        body[kVariantKey] = bestVariant;
    } else {
        // This happens when variants is empty or nil
        body[kVariantKey] = [NSNull null];
    }
}

/**
 * "variant": null JSON is tracked on null or empty variants and "count" field should be 1
 */
- (void)setCount:(NSArray *)variants dict:(NSMutableDictionary *)body {
    if ([variants count] <= 0) {
        body[kCountKey] = @1;
    } else {
        body[kCountKey] = @([variants count]);
    }
}

- (void)addReward:(double)reward forModel:(NSString *)modelName
{
    if(isnan(reward) || isinf(reward)) {
        NSString *reason = [NSString stringWithFormat:@"invalid reward: %lf, " \
                            "must not be NaN or +-Infinity", reward];
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
    }
    
    NSString *decisionId = [self lastDecisionIdOfModel:modelName];
    
    // this implementation is an enormous hack.  This is just the way the gym is at the moment
    // before the protocol redesign
    NSMutableDictionary *body = [@{ kTypeKey: kEventType } mutableCopy];

    [body setObject:@"Reward" forKey:kEventKey];
    [body setObject:modelName forKey:kModelKey];
    [body setObject:decisionId forKey:kDecisionIdKey];
    
    NSDictionary *properties = @{ kValueKey: [NSNumber numberWithDouble:reward]};
    [body setObject:properties forKey:kPropertiesKey];

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
        err = [NSError errorWithDomain:@"ai.improve.IMPDecisionTracker" code:-100 userInfo:@{NSLocalizedDescriptionKey:e.reason}];
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

- (nullable NSString *)createAndPersistDecisionIdForModel:(NSString *)modelName {
    NSString *ksuid = [NSString ksuidString];
    if(ksuid != nil) {
        NSString *key = [NSString stringWithFormat:kLastDecisionIdKey, modelName];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:ksuid forKey:key];
    }
    return ksuid;
}

- (nullable NSString *)lastDecisionIdOfModel:(NSString *)modelName {
    NSString *key = [NSString stringWithFormat:kLastDecisionIdKey, modelName];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [defaults objectForKey:key];
}

@end
