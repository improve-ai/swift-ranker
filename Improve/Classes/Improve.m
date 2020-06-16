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

/**
 Already loaded models mapped by their namespaces. A single model may have many namespaces.

 Initially nil. Then we load models from cache, if any, and then remote models.
 */
@property (strong, nonatomic) NSDictionary<NSString*, IMPModelBundle*> *modelBundlesByNamespace;

/**
 The model which handles requests without namespace. Initially is nil.

 Initially nil. Then is loaded from cache, if any, and then from the remote server.
 */
@property (strong, nonatomic) IMPModelBundle *defaultModel;

@property (strong, nonatomic) IMPModelDownloader *downloader;

@property (strong, atomic) NSString *historyId;

@property (strong, nonatomic) NSMutableArray *onReadyBlocks;

@end


@implementation Improve

@synthesize modelBundleUrl = _modelBundleUrl;

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
    self = [super init];
    if (!self) return nil;

    _isReady = NO;
    _onReadyBlocks = [NSMutableArray new];

    _apiKey = apiKey;
    _trackVariantsProbability = 0.01;
    
    _historyId = [[NSUserDefaults standardUserDefaults] stringForKey:kHistoryIdDefaultsKey];
    if (!_historyId) {
        _historyId = [self generateHistoryId];
        [[NSUserDefaults standardUserDefaults] setObject:_historyId forKey:kHistoryIdDefaultsKey];
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
        _modelBundleUrl = url;
        NSArray *cachedBundles = [IMPModelDownloader cachedModelBundles];
        if (cachedBundles) {
            [self fillNamespaceToModelsMap:cachedBundles];
        }

        [self loadModels:[NSURL URLWithString:url]];
    }
}

- (NSString *) modelBundleUrl {
    @synchronized (self) {
        return _modelBundleUrl;
    }
}

- (void) onReady:(void (^)(void)) block
{
    if (self.isReady) {
        block();
    } else {
        [self.onReadyBlocks addObject:block];
    }
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
    if (!variants || [variants count] == 0) {
        NSLog(@"+[%@ %@]: non-nil, non-empty array required for choose variants. returning nil.", CLASS_S, CMD_S);
        return nil;
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kChooseMethod,
            kVariantsKey: variants,
            kNamespaceKey: namespace
        }];
    }

    id chosen;

    if (namespace) {
        IMPChooser *chooser = [self chooserForNamespace:namespace];
        
        if (chooser) {
            chosen = [chooser choose:variants context:context];
            [self calculateAndTrackPropensityOfChosen:chosen
                                        amongVariants:variants
                                            inContext:context
                                          withChooser:chooser
                                           chooseDate:[NSDate date]];
        } else {
            NSLog(@"-[%@ %@]: Model not loaded. Choosing first variant.", CLASS_S, CMD_S);
        }
    } else {
        NSLog(@"+[%@ %@]: non-nil required for namespace. returning first variant.", CLASS_S, CMD_S);
    }
    
    if (!chosen) {
        return [variants objectAtIndex:0];
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
    if (!variants || [variants count] == 0) {
        NSLog(@"+[%@ %@]: non-nil, non-empty array required for sort variants. returning empty array", CLASS_S, CMD_S);
        return @[];
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kSortMethod,
            kVariantsKey: variants,
            kNamespaceKey: namespace
        }];
    }
    
    NSArray *sorted;
    if (namespace) {
        IMPChooser *chooser = [self chooserForNamespace:namespace];
        
        if (chooser) {
            sorted = [chooser sort:variants context:context];
        } else {
            NSLog(@"-[%@ %@]: Model not loaded. Returning unsorted shallow copy of variants.", CLASS_S, CMD_S);
        }
    } else {
        NSLog(@"+[%@ %@]: non-nil required for namespace. Return unsorted shallow copy of variants.", CLASS_S, CMD_S);
    }
    
    if (!sorted) {
        return [[NSArray alloc] initWithArray:variants];
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
    [self postImproveRequest:body
                         url:[NSURL URLWithString:_trackUrl]
                       block:^
     (NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
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
    
    if (self.apiKey) {
        [headers setObject:self.apiKey forKey:kApiKeyHeader];
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

- (IMPChooser *)chooserForNamespace:(nullable NSString *)namespaceStr
{
    IMPModelBundle *modelBundle;
    if (!namespaceStr || namespaceStr.length == 0) {
        modelBundle = self.defaultModel;
    } else {
        modelBundle= self.modelBundlesByNamespace[namespaceStr];
    }
    if (!modelBundle) {
        NSLog(@"-[%@ %@]: Model not found: %@", CLASS_S, CMD_S, namespaceStr);
        return nil;
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelBundle:modelBundle namespace:namespaceStr error:&error];
    if (!chooser) {
        NSLog(@"-[%@ %@]: %@", CLASS_S, CMD_S, error);
        return nil;
    }

    return chooser;
}

- (void)loadModels:(NSURL *) modelBundleUrl
{
    if (self.downloader && self.downloader.isLoading) return;

    self.downloader = [[IMPModelDownloader alloc] initWithURL:modelBundleUrl];
    self.downloader.headers = @{@"Content-Type": @"application/json",
                                kApiKeyHeader: self.apiKey};

    __weak Improve *weakSelf = self;
    [self.downloader loadWithCompletion:^(NSArray *bundles, NSError *error) {
        if (error) {
            NSLog(@"+[%@ %@]: %@", CLASS_S, CMD_S, error);

            // Reload
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadModels:modelBundleUrl];
            });
        } else if (bundles) {
            [weakSelf fillNamespaceToModelsMap:bundles];
            [weakSelf notifyDidLoadModels];
        }
    }];
}

/// Populates `modelBundlesByNamespace` and `defaultModel` properties.
- (void)fillNamespaceToModelsMap:(NSArray<IMPModelBundle *> *)models
{
    NSMutableDictionary *bundlesByNamespace = [NSMutableDictionary new];

    for (IMPModelBundle *bundle in models) {
        NSArray *namespaces = bundle.metadata.namespaces;
        if (namespaces.count == 0) {
            // Only the default model should have zero namespaces.
            self.defaultModel = bundle;
            continue;
        }
        for (NSString *namespaceString in namespaces) {
            bundlesByNamespace[namespaceString] = bundle;
        }
    }
    self.modelBundlesByNamespace = bundlesByNamespace;
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

- (void)calculateAndTrackPropensityOfChosen:(id)chosen
                              amongVariants:(NSArray *)variants
                                  inContext:(NSDictionary *)context
                                withChooser:(IMPChooser *)chooser
                                 chooseDate:(NSDate *)chooseDate
{
    if (self.propensityScoreTrialCount <= 1) return;

    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    dispatch_async(backgroundQueue, ^{
        NSUInteger repeats = 0;
        for (NSUInteger i = 0; i < self.propensityScoreTrialCount; i++)
        {
            NSDictionary *anotherChoice = [chooser choose:variants context:context];
            if ([chosen isEqual:anotherChoice]) {
                repeats += 1;
            }
        }
        double propensity = (double)(repeats + 1) / (double)(self.propensityScoreTrialCount + 1);

        NSDictionary *trackData = @{
            kTypeKey: kPropensityType,
            // Specify timestamp directly to override the default value
            kTimestampKey: [self timestampFromDate:chooseDate],
            kVariantKey: chosen,
            kContextKey: context,
            kPropensityKey: @(propensity)
        };

        [self track:trackData];
    });
}

- (void)notifyDidLoadModels {
    self.isReady = YES;
    for (void (^block)(void) in self.onReadyBlocks) {
        block();
    }
    [self.onReadyBlocks removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:ImproveDidLoadModelNotification object:self];
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
