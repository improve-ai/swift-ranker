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

@import Security;

typedef void(^ModelLoadCompletion)(BOOL isLoaded);

/// How soon model downloading will be retried in case of error.
const NSTimeInterval kRetryInterval;

NSString * const kHistoryIdKey = @"history_id";
NSString * const kTimestampKey = @"timestamp";
NSString * const kMessageIdKey = @"message_id";
NSString * const kTypeKey = @"type";
NSString * const kVariantKey = @"variant";
NSString * const kContextKey = @"context";
NSString * const kNamespaceKey = @"namespace";
NSString * const kRewardsKey = @"rewards";
NSString * const kPropensityKey = @"propensity";
NSString * const kVariantsKey = @"variants";
NSString * const kRewardKeyKey = @"reward_key";
NSString * const kMethodKey = @"method";
NSString * const kEventKey = @"event";
NSString * const kDecisionsKey = @"decisions";
NSString * const kPropertiesKey = @"properties";

NSString * const kDecisionType = @"decision";
NSString * const kRewardsType = @"rewards";
NSString * const kEventType = @"event";
NSString * const kVariantsType = @"variants";
NSString * const kPropensityType = @"propensity";

NSString * const kChooseMethod = @"choose";
NSString * const kSortMethod = @"sort";

NSString * const kApiKeyHeader = @"x-api-key";

NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";


NSNotificationName const ImproveDidLoadModelNotification = @"ImproveDidLoadModelNotification";

@interface Improve ()
// Private vars

/// Already loaded models

/* Initially empty. Then we load models from cache, if any, and
 then remote models. */
@property (strong, nonatomic) NSMutableDictionary<NSString*, IMPModelBundle*> *modelBundlesByName;

@property (strong, nonatomic) IMPModelDownloader *downloader;

@property (strong, atomic) NSString *historyId;

@end


@implementation Improve

static Improve *sharedInstance;

+ (Improve *)instance
{
    return sharedInstance;
}

+ (Improve *) instanceWithApiKey:(NSString *)apiKey
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] initWithApiKey:apiKey];
    });
    return sharedInstance;
}

- (instancetype)initWithApiKey:(NSString *)apiKey
{
    self.isReady = YES; // TODO remove

    self.apiKey = apiKey;
    self.trackVariantsProbability = 0.01;
    
    self.historyId = [[NSUserDefaults standardUserDefaults] stringForKey:kHistoryIdDefaultsKey];
    if (!self.historyId) {
        self.historyId = [self generateHistoryId];
        [[NSUserDefaults standardUserDefaults] setObject:self.historyId forKey:kHistoryIdDefaultsKey];
    }
    return self;
}

- (NSString *) generateHistoryId {
    int historyIdSize = 32; // 256 bits
    SInt8 bytes[historyIdSize];
    int status = SecRandomCopyBytes(kSecRandomDefault, historyIdSize, bytes);
    if (status != errSecSuccess) {
        NSLog(@"-[%@ %@]: SecRandomCopyBytes failed, status: %d", CLASS_S, CMD_S, status);
        return nil;
    }
    NSData *data = [[NSData alloc] initWithBytes:bytes length:historyIdSize];
    NSString *historyId = [data base64EncodedStringWithOptions:0];
    return historyId;
}

- (void) setModelBundleUrl:(NSString *) url {
    @synchronized (self) {
        self.modelBundleUrl = url;
        _modelBundlesByName = [[IMPModelDownloader cachedModelBundlesByName] mutableCopy];
        [self loadModels:[NSURL URLWithString:url]];
    }
}

- (NSString *) modelBundleUrl {
    @synchronized (self) {
        return self.modelBundleUrl;
    }
}

- (void) onReady:(void (^)(void)) block
{
    block(); // TODO implement
}


- (id) choose:(NSString *) namespace
     variants:(NSArray *) variants
{
    return [self choose:namespace variants:variants context:nil];
}

- (id) choose:(NSString *) namespace
     variants:(NSArray *) variants
      context:(NSDictionary *) context
{
    if (!variants) { // TODO variants length check
        NSLog(@"+[%@ %@]: non-nil required for choose variants. returning nil.", CLASS_S, CMD_S);
        return nil;
    }

    id chosen;

    if (namespace) {
        IMPChooser *chooser = [self chooserForNamespace:namespace];
        
        if (chooser) {
            chosen = [chooser choose:variants context:context];
        } else {
            NSLog(@"-[%@ %@]: Model not loaded. Choosing random variant.", CLASS_S, CMD_S);
        }
    } else {
        NSLog(@"+[%@ %@]: non-nil required for namespace. returning random variant.", CLASS_S, CMD_S);
    }
    
    if (!chosen) {
        chosen = [variants randomObject];
    }

    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kChooseMethod,
            kVariantsKey: variants,
            kNamespaceKey: namespace
        }];
    }

    return chosen;
}


- (NSArray *) sort:(NSString *) namespace
          variants:(NSArray *) variants
{
    return [self sort:namespace variants:variants context:nil];
}

- (NSArray *) sort:(NSString *) namespace
          variants:(NSArray *) variants
           context:(NSDictionary *) context
{
    if (!variants) { // TODO variants length check
        NSLog(@"+[%@ %@]: non-nil required for sort variants. returning nil", CLASS_S, CMD_S);
        return nil;
    }

    NSArray *sorted;
    if (namespace) {
        IMPChooser *chooser = [self chooserForNamespace:namespace];
        
        if (chooser) {
            sorted = [chooser sort:variants context:context];
        } else {
            NSLog(@"-[%@ %@]: Model not loaded. Sorting randomly.", CLASS_S, CMD_S);
        }
    } else {
        NSLog(@"+[%@ %@]: non-nil required for namespace. sorting randomly.", CLASS_S, CMD_S);
    }
    
    if (!sorted) {
        sorted = [self shuffleArray:variants];
    }

    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kSortMethod,
            kVariantsKey: variants,
            kNamespaceKey: namespace
        }];
    }

    return sorted;
}


- (void) chooseRemote:(NSString *) namespace
             variants:(NSArray *)variants
              context:(NSDictionary *)context
           completion:(void (^)(id, NSError *)) block
{
    if (!variants || !namespace || !_chooseUrl) {
        block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: @"namespace, variants, and _chooseUrl cannot be nil"}]);
        return;
    }

    NSMutableDictionary *body = [@{ kVariantsKey: variants} mutableCopy];
        
    if (context) {
        [body setObject:context forKey:kContextKey];
    }
        
    [body setObject:namespace forKey:kNamespaceKey];

    [self postImproveRequest:body url:[NSURL URLWithString:self.chooseUrl] block:^(NSObject *response, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            // is this a dictionary?
            if ([response isKindOfClass:[NSDictionary class]]) {
                // extract the chosen
                id chosen = [(NSDictionary *)response objectForKey:kVariantKey];
                if (chosen) {
                    block(chosen, nil);
                    return;
                }
            }
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"malformed response from choose: %@", response]}]);
        }
    }];

}

- (void) trackDecision:(NSString *) namespace
               variant:(id) variant
{
    [self trackDecision:namespace variant:variant context:nil rewardKey:nil];
}

- (void) trackDecision:(NSString *) namespace
               variant:(id) variant
               context:(NSDictionary *) context
{
    [self trackDecision:namespace variant:variant context:context rewardKey:nil];
}

- (void) trackDecision:(NSString *) namespace
               variant:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey
{
    if (!variant) {
        NSLog(@"+[%@ %@]: Skipping trackDecision for nil variant. To track null values use [NSNull null]", CLASS_S, CMD_S);
        return;
    }

    if (!namespace) {
        NSLog(@"+[%@ %@]: Skipping trackDecision for nil namespace", CLASS_S, CMD_S);
        return;
    }
    
    // the rewardKey is never nil
    if (!rewardKey) {
        rewardKey = namespace;
    }
    
    NSMutableDictionary *body = [@{ kVariantKey: variant,
                                    kNamespaceKey: namespace,
                                    kRewardKeyKey: rewardKey } mutableCopy];
    
    if (context) {
        [body setObject:context forKey:kContextKey];
    }
    
    [self postImproveRequest:body url:[NSURL URLWithString:_trackUrl] block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        }
    }];
}

- (void) trackReward:(NSString *) rewardKey value:(NSNumber *)reward
{
    if (rewardKey && reward) {
        [self trackRewards:@{ rewardKey: reward }];
    } else {
        NSLog(@"Skipping trackReward for nil rewardKey or reward");
    }
}

- (void) trackRewards:(NSDictionary *)rewards
{
    if (rewards) {
        [self track:@{
            kTypeKey: kRewardsType,
            kRewardsKey: rewards
        }];
    } else {
        NSLog(@"Skipping trackRewards for nil rewards");
    }
}

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties {
    [self trackAnalyticsEvent:event properties:properties attachDecisions:nil attachRewards:nil];
}

- (void) trackAnalyticsEvent:(NSString *)event properties:(NSDictionary *)properties attachDecisions:(NSArray *)decisions attachRewards:(NSDictionary *)rewards {
    
    NSMutableDictionary *body = [@{ kTypeKey: kEventType } mutableCopy];
    
    if (event) {
        [body setObject:event forKey:kEventKey];
    }
    if (properties) {
        [body setObject:properties forKey:kPropertiesKey];
    }
    if (decisions) {
        [body setObject:decisions forKey:kDecisionsKey];
    }
    if (rewards) {
        [body setObject:rewards forKey:kRewardsKey];
    }

    [self track:body];
}

- (void) track:(NSDictionary *) body {
    [self postImproveRequest:body url:[NSURL URLWithString:_trackUrl] block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        }
    }];
}

- (void) postImproveRequest:(NSDictionary *) bodyValues url:(NSURL *) url block:(void (^)(NSObject *, NSError *)) block
{
    if (!self.historyId) {
        block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: @"_historyId cannot be nil"}]);
        return;
    }

    NSMutableDictionary *headers = [@{ @"Content-Type": @"application/json" } mutableCopy];
    
    if (self.apiKey) {
        [headers setObject:self.apiKey forKey:kApiKeyHeader];
    }

    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);
    // Example: 2020-02-03T03:16:36.073Z
    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];

    NSMutableDictionary *body = [@{
        kTimestampKey: dateStr,
        kHistoryIdKey: self.historyId,
        kMessageIdKey: [[NSUUID UUID] UUIDString]
    } mutableCopy];
    
    [body addEntriesFromDictionary:bodyValues];
    
    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
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

- (IMPChooser *)chooserForNamespace:(NSString *)namespace
{
    IMPModelBundle *modelBundle = self.modelBundlesByName[namespace];
    if (!modelBundle) {
        NSLog(@"-[%@ %@]: Model not found: %@", CLASS_S, CMD_S, namespace);
        return nil;
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelBundle:modelBundle namespace:namespace error:&error];
    if (!chooser) {
        NSLog(@"-[%@ %@]: %@", CLASS_S, CMD_S, error);
        return nil;
    }

    return chooser;
}


// Recursively load models one by one
- (void)loadModels:(NSURL *) modelBundleUrl
{
    if (self.downloader && self.downloader.isLoading) return;

    self.downloader = [[IMPModelDownloader alloc] initWithURL:modelBundleUrl];

    __weak Improve *weakSelf = self;
    [self.downloader loadWithCompletion:^(NSDictionary *bundles, NSError *error) {
        if (error) {
            NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);

            // Reload
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadModels:modelBundleUrl];
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

    return self.trackVariantsProbability > drand48();
}

- (double)calculatePropensity:(id)chosen
                     variants:(NSArray *)variants
                      context:(NSDictionary *)context
                       domain:(NSString *)domain
               iterationCount:(NSUInteger)iterationCount
{
    IMPChooser *chooser = [self chooserForNamespace:domain];
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

/**
The new properties are extracted from variants for iterationCount times. Propensity score is the fraction of the times that
the initially chosen properties is chosen overall.

iterationCount is set to 9 by default.

@param domain A rewardable domain associated with the choosing
@param chosen The variant that was chosen by the `choose` function from the variants with the same
domain and context.

@returns The propensity value [0, 1.0], or -1 if there was an error. // FIX why would it return -1?
*/
- (double)calculatePropensity:(id)chosen
                     variants:(NSArray *)variants
                      context:(NSDictionary *)context
                       domain:(NSString *)domain
{
    return [self calculatePropensity:chosen
                            variants:variants
                              context:context
                              domain:domain
                      iterationCount:9];
}

- (NSArray*)shuffleArray:(NSArray*)array {

    NSMutableArray *copy = [[NSMutableArray alloc] initWithArray:array];

    for(NSUInteger i = [array count]; i > 1; i--) {
        NSUInteger j = arc4random_uniform((uint32_t) i);
        [copy exchangeObjectAtIndex:i-1 withObjectAtIndex:j];
    }

    return copy;
}

- (void)notifyDidLoadModels {
    [[NSNotificationCenter defaultCenter] postNotificationName:ImproveDidLoadModelNotification object:self];
}

@end
