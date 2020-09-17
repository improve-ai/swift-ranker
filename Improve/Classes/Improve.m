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
#import "IMPModelManager.h"
#import "IMPCredential.h"
#import "Constants.h"
#import "IMPModelBundle.h"

@import Security;

typedef void(^ModelLoadCompletion)(BOOL isLoaded);

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

NSString * const kHistoryIdDefaultsKey = @"ai.improve.history_id";

@interface Improve ()
// Private vars

@property (strong, atomic) NSString *historyId;

@property (strong, nonatomic) NSMutableArray *onReadyBlocks;

@end


@implementation Improve

+ (Improve *) instance
{
    return [self instanceWithNamespace:@""];
}

+ (Improve *) instanceWithNamespace:(NSString *)namespaceStr;
{
    static NSMutableDictionary<NSString *, Improve *> *instances;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instances = [NSMutableDictionary new];
    });

    @synchronized (instances)
    {
        if (!namespaceStr)
        {
            IMPErrLog("Non-nil required for namespace.");
            return nil;
        }

        Improve *existingInstance = instances[namespaceStr];
        if (existingInstance) {
            IMPLog("Returning existing instance for namespace: %@", namespaceStr);
            return existingInstance;
        } else {
            Improve *newInstance = [[Improve alloc] initWithNamespace:namespaceStr];
            instances[namespaceStr] = newInstance;
            IMPLog("Created instance for namespace: %@", namespaceStr);
            return newInstance;
        }
    }
}

+ (void) addModelUrl:(NSString *)urlStr apiKey:(NSString *)apiKey
{
    [[IMPModelManager sharedManager] addModelWithCredential:[IMPCredential credentialWithModelURL:[NSURL URLWithString:urlStr] apiKey:apiKey]];
}

+ (NSArray<IMPModelBundle*> *)sharedModels
{
    return [IMPModelManager sharedManager].models;
}

+ (IMPModelBundle *)modelForNamespace:(NSString *)namespaceStr
{
    return [[IMPModelManager sharedManager] modelForNamespace:namespaceStr];
}

- (instancetype) initWithNamespace:(NSString *)namespaceStr {
    self = [super init];
    if (!self) return nil;

    assert(namespaceStr != nil);
    _modelNamespace = namespaceStr;
    _onReadyBlocks = [NSMutableArray new];
    _trackVariantsProbability = 0.01;

    _historyId = [[NSUserDefaults standardUserDefaults] stringForKey:kHistoryIdDefaultsKey];
    if (!_historyId) {
        _historyId = [self generateHistoryId];
        [[NSUserDefaults standardUserDefaults] setObject:_historyId forKey:kHistoryIdDefaultsKey];
    }
    self.maxModelsStaleAge = kDefaultMaxModelStaleAge;

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(handleModelManagerDidLoadNotification:)
                               name:IMPModelManagerDidLoadNotification
                             object:nil];

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

- (void)setMaxModelsStaleAge:(NSTimeInterval)maxModelsStaleAge {
    [IMPModelManager sharedManager].maxModelsStaleAge = maxModelsStaleAge;
}

- (BOOL)isReady {
    return [[self class] modelForNamespace:self.modelNamespace] != nil;
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

- (id) choose:(NSArray *) variants
{
    return [self choose:variants context:nil];
}

- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context
{
    if (!variants || [variants count] == 0) {
        IMPErrLog("Non-nil, non-empty array required for choose variants. returning nil.");
        return nil;
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kChooseMethod,
            kVariantsKey: variants
        }];
    }

    id chosen;

    IMPChooser *chooser = [self chooser];
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
    
    if (!chosen) {
        IMPLog("Choosing first variant.");
        return [variants objectAtIndex:0];
    }

    return chosen;
}


- (NSArray *) sort:(NSArray *) variants
{
    return [self sort:variants context:nil];
}

- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context
{
    if (!variants || [variants count] == 0) {
        IMPLog("Non-nil, non-empty array required for sort variants. returning empty array");
        return @[];
    }
    
    if (self.shouldTrackVariants) {
        [self track:@{
            kTypeKey: kVariantsType,
            kMethodKey: kSortMethod,
            kVariantsKey: variants
        }];
    }
    
    NSArray *sorted;

    IMPChooser *chooser = [self chooser];
    if (chooser) {
        sorted = [chooser sort:variants context:context];
    } else {
        IMPLog("Model not loaded.");
    }
    
    if (!sorted) {
        IMPLog("Returning unsorted shallow copy of variants.");
        return [[NSArray alloc] initWithArray:variants];
    }

    return sorted;
}


- (void) chooseRemote:(NSArray *)variants
              context:(NSDictionary *)context
           completion:(void (^)(id, NSError *)) block
{
    if (!variants || !self.modelNamespace || !_chooseUrl) {
        block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: @"namespace, variants, and _chooseUrl cannot be nil"}]);
        return;
    }

    NSMutableDictionary *body = [@{ kVariantsKey: variants} mutableCopy];
        
    if (context) {
        [body setObject:context forKey:kContextKey];
    }
        
    [body setObject:self.modelNamespace forKey:kNamespaceKey];
    
    [body setObject:self.modelNamespace forKey:@"model"]; // DEPRECATED, compatibility with Improve v4
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

- (void) trackDecision:(id) variant
{
    [self trackDecision:variant context:nil rewardKey:nil];
}

- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
{
    [self trackDecision:variant context:context rewardKey:nil];
}

- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey
{
    [self trackDecision:variant
                context:context
              rewardKey:rewardKey
             completion:nil];
}

- (void) trackDecision:(id) variant
               context:(NSDictionary *) context
             rewardKey:(NSString *) rewardKey
            completion:(nullable IMPTrackCompletion) completionHandler
{
    if (!variant) {
        IMPErrLog("Skipping trackDecision for nil variant. To track null values use [NSNull null]");
        if (completionHandler) completionHandler(nil);
        return;
    }

    // the rewardKey is never nil
    if (!rewardKey) {
        IMPLog("Using namespace as rewardKey: %@", self.modelNamespace);
        if (completionHandler) completionHandler(nil);
        rewardKey = self.modelNamespace;
    }

    NSMutableDictionary *body = [@{ kTypeKey: kDecisionType,
                                    kVariantKey: variant,
                                    kNamespaceKey: self.modelNamespace,
                                    kRewardKeyKey: rewardKey } mutableCopy];

    if (context) {
        [body setObject:context forKey:kContextKey];
    }

    [self postImproveRequest:body url:[NSURL URLWithString:_trackUrl] block:^(NSObject *result, NSError *error) {
        if (error) {
            IMPErrLog("Improve.track error: %@", error);
            IMPLog("trackDecision failed! Namespace: %@, variant: %@, context: %@, rewardKey: %@", self.modelNamespace, variant, context, rewardKey);
        } else {
            IMPLog("trackDecision succeed with namespace: %@, variant: %@, context: %@, rewardKey: %@", self.modelNamespace, variant, context, rewardKey);
        }
        if (completionHandler) completionHandler(error);
    }];
}

- (void) addReward:(NSNumber *) reward forKey:(NSString *) rewardKey
{
    [self addReward:reward forKey:rewardKey completion:nil];
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
    [self postImproveRequest:body
                         url:[NSURL URLWithString:_trackUrl]
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
    
    if (self.trackApiKey) {
        [headers setObject:self.trackApiKey forKey:kApiKeyHeader];
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

// Namespace can't be changed now, so we can cache chooser?
- (IMPChooser *)chooser
{
    IMPModelBundle *modelBundle = [[self class] modelForNamespace:self.modelNamespace];
    if (!modelBundle) {
        IMPErrLog("Model not found for namespace %@", self.modelNamespace);
        return nil;
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelBundle:modelBundle namespace:self.modelNamespace error:&error];
    if (!chooser) {
        IMPErrLog("Failed to initialize Chooser: %@", error);
        return nil;
    }

    return chooser;
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
    IMPChooser *chooser = [self chooser];
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

- (void)handleModelManagerDidLoadNotification:(NSNotification *)note
{
    IMPModelBundle *loadedBundle = note.userInfo[@"model_bundle"];
    if ([loadedBundle.namespaces containsObject:self.modelNamespace]) {
        [self notifyOnReadyBlocks];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center removeObserver:self
                          name:IMPModelManagerDidLoadNotification
                        object:nil];
    }
}

- (void)notifyOnReadyBlocks
{
    for (void (^block)(void) in self.onReadyBlocks) {
        block();
    }
    [self.onReadyBlocks removeAllObjects];
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
