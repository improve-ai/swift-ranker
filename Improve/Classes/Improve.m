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
#import "IMPLogging.h"
#import "IMPModelDownloader.h"

@import Security;

typedef void(^ModelLoadCompletion)(BOOL isLoaded);

/// How soon model downloading will be retried in case of error.
const NSTimeInterval kRetryInterval = 30.0;

const NSTimeInterval kDefaultMaxModelStaleAge = 604800.0;

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
 The model which handles requests without namespace or with any missing namespace. Initially is nil.
 Initially nil. Then is loaded from cache, if any, and then from the remote server.
 */
@property (strong, nonatomic) IMPModelBundle *defaultModel;

@property (strong, nonatomic) IMPModelDownloader *downloader;

@property (strong, atomic) NSString *historyId;

@property (strong, nonatomic) NSMutableArray *onReadyBlocks;

/// Becomes YES after you call `-initializeWithApiKey:modelBundleURL:`
@property (readonly) BOOL isInitialized;

@end


@implementation Improve

@synthesize modelBundleUrl = _modelBundleUrl;
@synthesize maxModelsStaleAge = _maxModelsStaleAge;

static Improve *sharedInstance;

+ (Improve *) instance
{
    return [self instanceWithName:@""];
}

+ (Improve *) instanceWithName:(NSString *)name
{
    static NSMutableDictionary<NSString *, Improve *> *instances;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [NSMutableDictionary new];
    });

    @synchronized (instances)
    {
        Improve *existingInstance = instances[name];
        if (existingInstance) {
            IMPLog("Returning existing instance for name: %@", name);
            return existingInstance;
        } else {
            Improve *newInstance = [[Improve alloc] init];
            instances[name] = newInstance;
            IMPLog("Created instance for name: %@", name);
            return newInstance;
        }
    }
}

- (instancetype) init {
    self = [super init];
    if (!self) return nil;

    _onReadyBlocks = [NSMutableArray new];
    _trackVariantsProbability = 0.01;

    _historyId = [[NSUserDefaults standardUserDefaults] stringForKey:kHistoryIdDefaultsKey];
    if (!_historyId) {
        _historyId = [self generateHistoryId];
        [[NSUserDefaults standardUserDefaults] setObject:_historyId forKey:kHistoryIdDefaultsKey];
    }
    _maxModelsStaleAge = kDefaultMaxModelStaleAge;
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

- (void) initializeWithApiKey:(NSString *)apiKey modelBundleURL:(NSString *)urlStr
{
    if (self.isInitialized) {
        IMPLog("Trying to initialize more than once! Ignoring.");
        return;
    }
    self.apiKey = apiKey;
    self.modelBundleUrl = urlStr;
    _isInitialized = YES;
}

- (void) setModelBundleUrl:(NSString *) url {
    @synchronized (self) {
        _modelBundleUrl = url;
        [self loadModels:[NSURL URLWithString:url]];
    }
}

- (NSString *) modelBundleUrl {
    @synchronized (self) {
        return _modelBundleUrl;
    }
}

- (void)setMaxModelsStaleAge:(NSTimeInterval)maxModelsStaleAge {
    @synchronized (self) {
        _maxModelsStaleAge = maxModelsStaleAge;
        [self loadModels:[NSURL URLWithString:self.modelBundleUrl]];
    }
}

- (NSTimeInterval)maxModelsStaleAge {
    @synchronized(self) {
        return _maxModelsStaleAge;
    }
}

- (BOOL)isReady {
    if (self.downloader) {
        return (self.downloader.cachedModelsAge > self.maxModelsStaleAge
                && self.modelBundlesByNamespace != nil
                && self.modelBundlesByNamespace.count > 0);
    } else {
        return false;
    }
}

- (void) onReady:(void (^)(void)) block
{
    // check stale age right here
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
        IMPErrLog("Non-nil, non-empty array required for choose variants. returning nil.");
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
            IMPLog("Model not loaded.");
        }
    } else {
        IMPErrLog("Non-nil required for namespace!");
    }
    
    if (!chosen) {
        IMPLog("Choosing first variant.");
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
        IMPLog("Non-nil, non-empty array required for sort variants. returning empty array");
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
            IMPLog("Model not loaded.");
        }
    } else {
        IMPErrLog("Non-nil required for namespace.");
    }
    
    if (!sorted) {
        IMPLog("Returning unsorted shallow copy of variants.");
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
    
    [body setObject:namespace forKey:@"model"]; // DEPRECATED, compatibility with Improve v4
    [body setObject:_historyId forKey:@"user_id"]; // DEPRECATED, compatibility with Improve v4

    [self postImproveRequest:body url:[NSURL URLWithString:self.chooseUrl] block:^(NSObject *response, NSError *error) {
        if (error) {
            block(nil, error);
        } else {
            // is this a dictionary?
            if ([response isKindOfClass:[NSDictionary class]]) {
                // extract the chosen variant
                id chosen = [(NSDictionary *)response objectForKey:kVariantKey];
                if (!chosen) {
                    chosen = [(NSDictionary *)response objectForKey:@"properties"]; // DEPRECATED, compatibility with Improve v4
                }
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
        IMPErrLog("Skipping trackDecision for nil variant. To track null values use [NSNull null]");
        return;
    }

    if (!namespace) {
        IMPErrLog("Skipping trackDecision for nil namespace");
        return;
    }
    
    // the rewardKey is never nil
    if (!rewardKey) {
        IMPLog("Using namespace as rewardKey: %@", namespace);
        rewardKey = namespace;
    }
    
    NSMutableDictionary *body = [@{ kTypeKey: kDecisionType,
                                    kVariantKey: variant,
                                    kNamespaceKey: namespace,
                                    kRewardKeyKey: rewardKey } mutableCopy];
    
    if (context) {
        [body setObject:context forKey:kContextKey];
    }
    
    [self postImproveRequest:body url:[NSURL URLWithString:_trackUrl] block:^(NSObject *result, NSError *error) {
        if (error) {
            IMPErrLog("Improve.track error: %@", error);
            IMPLog("trackDecision failed! Namespace: %@, variant: %@, context: %@, rewardKey: %@", namespace, variant, context, rewardKey);
        } else {
            IMPLog("trackDecision succeed with namespace: %@, variant: %@, context: %@, rewardKey: %@", namespace, variant, context, rewardKey);
        }
    }];
}

- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey
{
    if (rewardKey && reward) {
        [self addRewards:@{ rewardKey: reward }];
    } else {
        IMPErrLog("Skipping trackReward for nil rewardKey or reward");
    }
}

- (void) addRewards:(NSDictionary *)rewards
{
    if (rewards) {
        IMPLog("Tracking rewards: %@", rewards);
        [self track:@{
            kTypeKey: kRewardsType,
            kRewardsKey: rewards
        }];
    } else {
        IMPErrLog("Skipping trackRewards for nil rewards");
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
    [self postImproveRequest:body
                         url:[NSURL URLWithString:_trackUrl]
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

- (IMPChooser *)chooserForNamespace:(nullable NSString *)namespaceStr
{
    IMPModelBundle *modelBundle;
    if (!namespaceStr || namespaceStr.length == 0) {
        modelBundle = self.defaultModel;
    } else {
        modelBundle= self.modelBundlesByNamespace[namespaceStr];
    }
    if (!modelBundle && self.defaultModel != nil) {
        modelBundle = self.defaultModel;
    } else {
        IMPErrLog("Model not found for namespace %@. Default model is also nil.", namespaceStr);
        return nil;
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelBundle:modelBundle namespace:namespaceStr error:&error];
    if (!chooser) {
        IMPErrLog("Failed to initialize Chooser: %@", error);
        return nil;
    }

    return chooser;
}

- (void)loadModels:(NSURL *) modelBundleUrl
{
    IMPLog("Initializing model loading...");
    if (self.downloader && self.downloader.isLoading) {
        IMPLog("Allready loading. Skipping.");
        return;
    }

    IMPModelDownloader *downloader = [[IMPModelDownloader alloc] initWithURL:modelBundleUrl];
    self.downloader = downloader;
    IMPLog("Checking for cached models...");
    if (downloader.cachedModelsAge < self.maxModelsStaleAge) {
        // Load models from cache
        IMPLog("Found cached models. Finished.");
        NSArray *cachedModels = downloader.cachedModelBundles;
        if (cachedModels.count > 0) {
            [self fillNamespaceToModelsMap:cachedModels];
            [self notifyDidLoadModels];
        }
        return;
    }

    // Load remote models
    IMPLog("No cached models. Starting download...");
    downloader.headers = @{kApiKeyHeader: self.apiKey};

    __weak Improve *weakSelf = self;
    [downloader loadWithCompletion:^(NSArray *bundles, NSError *error) {
        if (error) {
            IMPErrLog("Failed to load models: %@", error);

            // Reload
            IMPLog("Will retry after %g sec", kRetryInterval);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                IMPLog("Retrying...");
                [weakSelf loadModels:modelBundleUrl];
            });
        } else if (bundles) {
            IMPLog("Models loaded.");
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
