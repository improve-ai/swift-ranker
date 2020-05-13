//
//  Improve.m
//  7Second
//
//  Created by Choosy McChooseFace on 9/6/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Improve.h"
#import "IMPChooser.h"
#import "NSArray+Random.h"
#import "IMPCommon.h"
#import "IMPModelDownloader.h"
#import "IMPModelMetadata.h"

typedef void(^ModelLoadCompletion)(BOOL isLoaded);

#define TRACK_URL @"https://api.improve.ai/v3/track"

/// How soon model downloading will be retried in case of error.
const NSTimeInterval kRetryInterval;

NSString * const kDefaultDomain = @"default";
NSString * const kDefaultRewardKey = kDefaultDomain;

NSString * const kHistoryIdKey = @"history_id";
NSString * const kTimestampKey = @"timestamp";
NSString * const kMessageIdKey = @"message_id";
NSString * const kTypeKey = @"type";
NSString * const kChosenKey = @"chosen";
NSString * const kContextKey = @"context";
NSString * const kDomainKey = @"domain";
NSString * const kRewardsKey = @"rewards";
NSString * const kVariantsKey = @"variants";
NSString * const kRewardKeyKey = @"reward_key";
NSString * const kMethodKey = @"method";

NSString * const kDecisionType = @"decision";
NSString * const kRewardsType = @"rewards";
NSString * const kEventType = @"event";
NSString * const kVariantsType = @"variants";

NSString * const kChooseMethod = @"choose";
NSString * const kSortMethod = @"sort";

NSString * const kApiKeyHeader = @"x-api-key";


NSNotificationName const ImproveDidLoadModelsNotification = @"ImproveDidLoadModelsNotification";

@interface IMPConfiguration ()
- (NSURL *) modelURLForName:(NSString *)modelName;
@end


@interface Improve ()
// Private vars

@property (nonatomic, strong) NSString *trackUrl;

@property (strong, nonatomic) IMPConfiguration *configuration;

/// Already loaded models
@property (strong, nonatomic)

/* Initially empty. Then we load models from cache, if any, and
 then remote models. */
NSMutableDictionary<NSString*, IMPModelBundle*> *modelBundlesByName;

@property (strong, nonatomic) IMPModelDownloader *downloader;

@end


@implementation Improve

static Improve *sharedInstance;

+ (Improve *) instance
{
    return sharedInstance;
}

+ (void) configureWith:(IMPConfiguration *)configuration
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithConfiguration:configuration];
    });
}

- (instancetype) initWithConfiguration:(IMPConfiguration *)config
{
    self = [super init];
    if (!self) return nil;

    _configuration = config;
    _modelBundlesByName = [[IMPModelDownloader cachedModelBundlesByName] mutableCopy];

    _trackUrl = TRACK_URL;

    [self loadModelsForConfiguration:config];

    return self;
}

- (NSString *) apiKey {
    return self.configuration.apiKey;
}

- (void) setApiKey:(NSString *)apiKey {
    self.configuration.apiKey = apiKey;
}

- (NSDictionary *) choose:(NSDictionary *)variants
                   context:(NSDictionary *)context
                   domain:(NSString *)domain
                rewardKey:(NSString *)rewardKey
                autoTrack:(BOOL)autoTrack
{
    if (!variants) {
        NSLog(@"+[%@ %@]: non-nil required for choose variants. returning nil.", CLASS_S, CMD_S);
        return nil;
    }
    
    // the domain is never nil for choose, sort, or trackChosen
    if (!domain) {
        domain = kDefaultDomain;
    }
    
    IMPChooser *chooser = [self chooserForDomain:domain];
    
    NSDictionary *chosen;
    
    if (chooser) {
        chosen = [chooser choose:variants context:context];
    } else {
        chosen = [self chooseRandom:variants];
    }
    
    if (autoTrack) {
        // trackChosen takes care of assigning the rewardKey to the domain on nil rewardKey
        [self trackChosen:chosen context:context domain:domain rewardKey:rewardKey];
    }

    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kChooseMethod,
            kVariantsKey: variants,
            kDomainKey: domain
        }];
    }
    
    [self notifyDidChoose:chosen fromVariants:variants context:context domain:domain];
    return chosen;
}


- (NSArray<NSDictionary*> *) sort:(NSArray<NSDictionary*> *)variants
                          context:(NSDictionary *)context
                           domain:(NSString *)domain
{
    if (!variants) {
        NSLog(@"+[%@ %@]: non-nil required for sort variants. returning nil", CLASS_S, CMD_S);
        return nil;
    }

    if (!domain) {
        domain = kDefaultDomain;
    }
    
    IMPChooser *chooser = [self chooserForDomain:domain];
    
    NSArray *sorted;
    if (chooser) {
        sorted = [chooser sort:variants context:context];
    } else {
        sorted = [self shuffleArray:variants];
    }

    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kSortMethod,
            kVariantsKey: variants,
            kDomainKey: domain
        }];
    }

    [self notifyDidSort:sorted fromVariants:variants context:context domain:domain];
    return sorted;
}


- (void) chooseRemote:(NSArray *)variants
               context:(NSDictionary *)context
               domain:(NSString *)domain
                  url:(NSURL *)chooseURL
           completion:(void (^)(NSDictionary *, NSError *)) block
{
    if (!variants) {
        block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: @"variants cannot be nil"}]);
        return;
    }
    
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               kApiKeyHeader:  self.apiKey };


    NSMutableDictionary *body = [@{ kVariantsKey: variants} mutableCopy];
        
    if (context) {
        [body setObject:context forKey:kContextKey];
    }

    if (!domain) {
        domain = kDefaultDomain;
    }
        
    [body setObject:domain forKey:kDomainKey];

    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        block(nil, err);
        return;
    }

    // TODO decide if variants and decision tracking should be handled here or in the remote choose
    [self postChooseRequest:headers
                       data:postData
                        url:chooseURL
                      block:block];
}

- (void) trackChosen:(id)chosen
{
    [self trackChosen:chosen context:nil domain:nil rewardKey:nil];
}

- (void) trackChosen:(id)chosen context:(NSDictionary *)context
{
    [self trackChosen:chosen context:context domain:nil rewardKey:nil];
}

- (void) trackChosen:(id)chosen context:(NSDictionary *)context domain:(NSString *)domain
{
    [self trackChosen:chosen context:context domain:domain rewardKey:nil];
}

- (void) trackChosen:(id)chosen context:(NSDictionary *)context domain:(NSString *)domain rewardKey:(NSString *)rewardKey
{
    if (!chosen) {
        NSLog(@"+[%@ %@]: Skipping trackChosen for nil chosen value. To track null values use [NSNull null]", CLASS_S, CMD_S);
        return;
    }
    
    // the tracked domain is never nil
    if (!domain) {
        domain = kDefaultDomain;
    }
    
    // the tracked rewardKey is never nil
    if (!rewardKey) {
        rewardKey = domain;
    }
    
    NSMutableDictionary *body = [@{ kChosenKey: chosen,
                                    kDomainKey: domain,
                                    kRewardKeyKey: rewardKey } mutableCopy];
    
    if (context) {
        [body setObject:context forKey:kContextKey];
    }
    
    [self track:body];
}

- (void) trackReward:(NSNumber *)reward
{
    if (reward) {
        // This will match a trackChosen with a nil domain and nil rewardKey
        [self trackRewards:@{ kDefaultRewardKey: reward }];
    } else {
        NSLog(@"Skipping trackReward for nil reward");
    }
}

- (void) trackRewards:(NSDictionary *)rewards
{
    if (rewards) {
        [self track:@{ kTypeKey: kRewardsType,
                       kRewardsKey: rewards}];
    } else {
        NSLog(@"Skipping trackRewards for nil rewards");
    }
}

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties {
    [self trackAnalyticsEvent:event properties:properties];
}
/*
- (void) track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    NSMutableDictionary *body = [@{ @"type": chosen,
                                    @"domain": domain,
                                    @"rewardKey": rewardKey } mutableCopy];
    if (event) {
        [bodyValues setObject:event forKey:@"event"];
    }
    if (properties) {
        [bodyValues setObject:properties forKey:@"properties"];
    }
    if (context) {
        [bodyValues setObject:context forKey:@"context"];
    }

    [self track:bodyValues];
}*/

- (void) track:(NSDictionary *)bodyValues completion:(void(^)(BOOL))handler
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               kApiKeyHeader: self.apiKey };

    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);
    // Example: 2020-02-03T03:16:36.073Z
    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];

    NSMutableDictionary *body = [@{
        kTimestampKey: dateStr,
        kHistoryIdKey: self.configuration.historyId,
        kMessageIdKey: [[NSUUID UUID] UUIDString]
    } mutableCopy];
    [body addEntriesFromDictionary:bodyValues];

    if (![self askDelegateShouldTrack:body]) {
        // Event canceled by delegate
        if (handler) handler(false);
        return;
    }

    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        NSLog(@"Improve.track error: %@", err);
        if (handler) handler(false);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_trackUrl]];

    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];

    __weak Improve *weakSelf = self;
    [self postImproveRequest:request block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
            if (handler) handler(false);
        } else {
            [weakSelf notifyDidTrack:body];
            if (handler) handler(true);
        }
    }];
}

- (void) track:(NSDictionary *)bodyValues {
    [self track:bodyValues completion:nil];
}

- (void) postChooseRequest:(NSDictionary *)headers
                      data:(NSData *)postData
                       url:(NSURL *)url
                     block:(void (^)(NSDictionary *, NSError *)) block
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];
    
    [self postImproveRequest:request block:^(NSObject *response, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            /*
             The response from chooseRemote looks like this:
             {
             "chosen": {
             "key": "value"
             }
             }
             */
            // is this a dictionary?
            if ([response isKindOfClass:[NSDictionary class]]) {
                // extract the chosen
                NSObject *chosen = [(NSDictionary *)response objectForKey:kChosenKey];
                if ([chosen isKindOfClass:[NSDictionary class]]) {
                    block((NSDictionary *)chosen, nil);
                    return;
                }
            }
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"malformed response from choose: %@", response]}]);
        }
    }];
}

- (void) postImproveRequest:(NSURLRequest *)request block:(void (^)(NSObject *, NSError *)) block
{

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

- (IMPChooser *)chooserForDomain:(NSString *)domain
{
    IMPModelBundle *modelBundle = self.modelBundlesByName[domain];
    if (!modelBundle) {
        NSLog(@"-[%@ %@]: Model not found: %@", CLASS_S, CMD_S, domain);
        return nil;
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelBundle:modelBundle error:&error];
    if (!chooser) {
        NSLog(@"-[%@ %@]: %@", CLASS_S, CMD_S, error);
        return nil;
    }

    return chooser;
}


// Recursively load models one by one
- (void)loadModelsForConfiguration:(IMPConfiguration *)configuration
{
    if (self.downloader && self.downloader.isLoading) return;

    self.downloader = [[IMPModelDownloader alloc] initWithURL:configuration.remoteModelsArchiveURL];

    __weak Improve *weakSelf = self;
    [self.downloader loadWithCompletion:^(NSDictionary *bundles, NSError *error) {
        if (error) {
            NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);

            // Reload
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadModelsForConfiguration:configuration];
            });
        } else if (bundles) {
            [weakSelf.modelBundlesByName setDictionary:bundles];
            [weakSelf notifyDidLoadModels];
        }
    }];
}

- (BOOL)shouldTrackVariants {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        srand48(time(0));
    });

    return self.configuration.variantTrackProbability > drand48();
}

- (double)calculatePropensity:(NSDictionary *)variants
                       domain:(NSString *)domain
                      context:(NSDictionary *)context
                       chosen:(NSDictionary *)chosen
               iterationCount:(NSUInteger)iterationCount
{
    IMPChooser *chooser = [self chooserForDomain:domain];
    if (!chooser) {
        return -1;
    }

    NSUInteger repeats = 0;
    for (NSUInteger i = 0; i < iterationCount; i++)
    {
        NSDictionary *otherProperties = [chooser choose:variants context:context];
        if ([chosen isEqualToDictionary:otherProperties]) {
            repeats += 1;
        }
    }
    double propensity = 1.0 / (double)(repeats + 1);
    return propensity;
}

- (double)calculatePropensity:(NSDictionary *)variants
                       domain:(NSString *)domain
                      context:(NSDictionary *)context
                       chosen:(NSDictionary *)chosen
{
    return [self calculatePropensity:variants
                              domain:domain
                             context:context
                              chosen:chosen
                      iterationCount:9];
}

- (NSDictionary *)chooseRandom:(NSDictionary *)variants
{
    NSMutableDictionary *randomProperties = [NSMutableDictionary new];

    for (NSString *key in variants)
    {
        NSArray *array = INSURE_CLASS(variants[key], [NSArray class]);
        if (!array) { continue; }

        randomProperties[key] = array.randomObject;
    }

    return randomProperties;
}

- (NSArray*)shuffleArray:(NSArray*)array {

    NSMutableArray *temp = [[NSMutableArray alloc] initWithArray:array];

    for(NSUInteger i = [array count]; i > 1; i--) {
        NSUInteger j = arc4random_uniform((uint32_t) i);
        [temp exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }

    return [NSArray arrayWithArray:temp];
}

#pragma mark Delegate helpers

- (void)notifyDidLoadModels {
    SEL selector = @selector(notifyDidLoadModels);
    if (self.delegate && [self.delegate respondsToSelector:selector])
    {
        [self.delegate improveDidLoadModels:self];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ImproveDidLoadModelsNotification object:self];
}

- (void)notifyDidChoose:(NSDictionary *)chosen
           fromVariants:(NSDictionary *)variants
                context:(NSDictionary *)context
                 domain:(NSString *)domain
{
    SEL selector = @selector(notifyDidChoose:fromVariants:context:domain:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didChoose:chosen fromVariants:variants context:context domain:domain ];
}

- (void)notifyDidSort:(NSArray *)sorted
         fromVariants:(NSArray *)variants
              context:(NSDictionary *)context
               domain:(NSString *)domain
{
    SEL selector = @selector(notifyDidSort:fromVariants:context:domain:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didSort:sorted fromVariants:variants context:context domain:domain ];
}

- (BOOL)askDelegateShouldTrack:(NSMutableDictionary *)eventBody {
    SEL selector = @selector(improve:shouldTrack:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return true;

    return [self.delegate improve:self shouldTrack:eventBody];
}

- (void)notifyDidTrack:(NSDictionary *)eventBody
{
    SEL selector = @selector(improve:didTrack:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didTrack:eventBody];
}

@end
