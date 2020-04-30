//
//  Improve.m
//  7Second
//
//  Created by Justin Chapweske on 9/6/16.
//  Copyright © 2016-2017 Impressive Sounding, LLC. All rights reserved.
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
    _modelBundlesByName = [NSMutableDictionary new];

    _trackUrl = TRACK_URL;

    [self loadModelsForConfiguration:config];

    return self;
}

// Legacy
- (NSString *) apiKey {
    return self.configuration.apiKey;
}

- (void) setApiKey:(NSString *)apiKey {
    self.configuration.apiKey = apiKey;
}

- (NSString *)userId {
    return self.configuration.userId;
}

- (NSDictionary *) choose:(NSDictionary *)variants
                   action:(NSString *)action
                  context:(NSDictionary *)context
{
    NSString *modelName = action;
    IMPChooser *chooser = [self chooserForModelWithName:modelName];
    if (!chooser) {
        NSDictionary *randomVariants = [self chooseRandom:variants context:context];
        [self notifyDidChoose:randomVariants fromVariants:variants forAction:action context:context];
        return randomVariants;
    }

    NSDictionary *properties = [chooser choose:variants context:context];

    NSDictionary *trackData = @{
        @"type": @"chosen",
        @"properties": properties,
        @"model": modelName,
        @"context": context
    };
    [self track:trackData];

    if (self.shouldTrackVariants) {
        [self track:@{
            @"type": @"variants",
            @"method": @"choose",
            @"variants": variants,
            @"model": modelName
        }];
    }

    [self notifyDidChoose:properties fromVariants:variants forAction:action context:context];
    return properties;
}

- (NSDictionary *)chooseRandom:(NSDictionary *)variants context:(NSDictionary *)context
{
    NSMutableDictionary *randomProperties = [context mutableCopy];

    for (NSString *key in variants)
    {
        NSArray *array = INSURE_CLASS(variants[key], [NSArray class]);
        if (!array) { continue; }

        randomProperties[key] = array.randomObject;
    }

    return randomProperties;
}

- (void) chooseRemote:(NSDictionary *)variants
               action:(NSString *)modelName
              context:(NSDictionary *)context
                  url:(NSURL *)chooseURL
           completion:(void (^)(NSDictionary *, NSError *)) block
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  self.apiKey };


    NSMutableDictionary *body = [@{ @"variants": variants,
                                    @"model": modelName,
                                    @"user_id": self.userId } mutableCopy];

    if (context) {
        [body setObject:context forKey:@"context"];
    }

    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        NSLog(@"Improve.chooseFrom error: %@", err);
        return;
    }

    [self postChooseRequest:headers
                       data:postData
                        url:chooseURL
                      block:block];
}

- (void) track:(NSString *)event properties:(NSDictionary *)properties {
    [self track:event properties:properties context:nil];
}

- (void) track:(NSString *)event properties:(NSDictionary *)properties context:(NSDictionary *)context
{
    NSMutableDictionary *bodyValues = [NSMutableDictionary new];
    if (event) {
        [bodyValues setObject:event forKey:@"event"];
    }
    if (properties) {
        [bodyValues setObject:properties forKey:@"properties"];
    }
    if (context) {
        [bodyValues setObject:context forKey:@"context"];
    }

    __weak Improve *weakSelf = self;
    [self track:bodyValues completion:^(BOOL success) {
        [weakSelf notifyDidTrack:event properties:properties context:context];
    }];
}

- (void) track:(NSDictionary *)bodyValues completion:(void(^)(BOOL))handler
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key": self.apiKey };

    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);
    // Example: 2020-02-03T03:16:36.073Z
    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];



    NSMutableDictionary *body = [@{
        @"user_id": self.userId,
        @"timestamp": dateStr,
        @"history_id": self.configuration.historyId,
        @"message_id": [[NSUUID UUID] UUIDString]
    } mutableCopy];
    [body addEntriesFromDictionary:bodyValues];

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

    [self postImproveRequest:request block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
            if (handler) handler(false);
        } else {
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
             "properties": {
             "key": "value"
             }
             }
             */
            // is this a dictionary?
            if ([response isKindOfClass:[NSDictionary class]]) {
                // extract the properties
                NSObject *properties = [(NSDictionary *)response objectForKey:@"properties"];
                if ([properties isKindOfClass:[NSDictionary class]]) {
                    block((NSDictionary *)properties, nil);
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

- (IMPChooser *)chooserForModelWithName:(NSString *)modelName
{
    IMPModelBundle *modelBundle = self.modelBundlesByName[modelName];
    if (!modelBundle) {
        NSLog(@"-[%@ %@]: Model not found: %@", CLASS_S, CMD_S, modelName);
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

- (NSArray<NSDictionary*> *) rank:(NSArray<NSDictionary*> *)variants
                           action:(NSString *)action
                          context:(NSDictionary *)context
{
    NSString *modelName = action;
    IMPChooser *chooser = [self chooserForModelWithName:modelName];
    if (!chooser) {
        return variants;
    }

    if (self.shouldTrackVariants) {
        [self track:@{
            @"type": @"variants",
            @"method": @"rank",
            @"variants": variants,
            @"model": modelName
        }];
    }

    NSArray *rankedVariants = [chooser rank:variants context:context];
    [self notifyDidRank:rankedVariants forAction:action context:context];
    return rankedVariants;
}

- (NSArray<NSDictionary*> *) rankAllPossible:(NSDictionary<NSString*, NSArray*> *)variantMap
                                      action:(NSString *)modelName
                                     context:(NSDictionary *)context
{
    NSArray<NSDictionary*> *combinations = [self combinationsFromVariants:variantMap];
    NSArray<NSDictionary*> *ranked = [self rank:combinations action:modelName context:context];
    return ranked;
}

- (NSArray<NSDictionary*> *) combinationsFromVariants:(NSDictionary<NSString*, NSArray*> *)variantMap
{
    // Store keys to preserve it's order during iteration
    NSArray *keys = variantMap.allKeys;

    // NSString: NSNumber, options count for each key
    NSUInteger *counts = calloc(keys.count, sizeof(NSUInteger));
    // Numbe of all possible variant combinations
    NSUInteger factorial = 1;
    for (NSUInteger i = 0; i < keys.count; i++) {
        NSString *key = keys[i];
        NSUInteger count = [variantMap[key] count];
        counts[i] = count;
        factorial *= count;
    }

    /* A series of indexes identifying a particular combination of elements
     selected in the map for each key */
    NSUInteger *indexes = calloc(variantMap.count, sizeof(NSUInteger));

    NSMutableArray *combos = [NSMutableArray arrayWithCapacity:factorial];

    BOOL finished = NO;
    while (!finished) {
        NSMutableDictionary *variant = [NSMutableDictionary dictionaryWithCapacity:keys.count];
        BOOL shouldIncreaseIndex = YES;
        for (NSUInteger i = 0; i < keys.count; i++) {
            NSString *key = keys[i];
            NSArray *options = variantMap[key];
            variant[key] = options[indexes[i]];

            if (shouldIncreaseIndex) {
                indexes[i] += 1;
            }
            if (indexes[i] >= counts[i]) {
                if (i == keys.count - 1) {
                    finished = YES;
                } else {
                    indexes[i] = 0;
                }
            } else {
                shouldIncreaseIndex = NO;
            }
        }
        [combos addObject:variant];
    }

    free(counts);
    free(indexes);

    return combos;
}

// Recursively load models one by one
- (void)loadModelsForConfiguration:(IMPConfiguration *)configuration
{
    if (self.downloader && self.downloader.isLoading) return;

    self.downloader = [[IMPModelDownloader alloc] initWithURL:configuration.remoteModelsArchiveURL];

    __weak Improve *weakSelf = self;
    [self.downloader loadWithCompletion:^(NSDictionary *bundles, NSError *error) {
        if (error) {
            NSLog(@"Model loading error: %@", error);

            // Reload
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf loadModelsForConfiguration:configuration];
            });
        } else if (bundles) {
            [weakSelf.modelBundlesByName setDictionary:bundles];
            [weakSelf notifyDidLoadModels];
        }

        // TODO: if (completion) completion(isLoaded);
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
                        action:(NSString *)modelName
                      context:(NSDictionary *)context
             chosenProperties:(NSDictionary *)properties
               iterationCount:(NSUInteger)iterationCount
{
    IMPChooser *chooser = [self chooserForModelWithName:modelName];
    if (!chooser) {
        return -1;
    }

    NSUInteger repeats = 0;
    for (NSUInteger i = 0; i < iterationCount; i++)
    {
        NSDictionary *otherProperties = [chooser choose:variants context:context];
        if ([properties isEqualToDictionary:otherProperties]) {
            repeats += 1;
        }
    }
    double propensity = 1.0 / (double)(repeats + 1);
    return propensity;
}

- (double)calculatePropensity:(NSDictionary *)variants
                        action:(NSString *)modelName
                      context:(NSDictionary *)context
             chosenProperties:(NSDictionary *)properties
{
    return [self calculatePropensity:variants
                               action:modelName
                             context:context
                    chosenProperties:properties
                      iterationCount:9];
}

#pragma mark Delegate helpers

- (void)notifyDidLoadModels {
    SEL selector = @selector(notifyDidLoadModels);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improveDidLoadModels:self];
}

- (void)notifyDidChoose:(NSDictionary *)chosenVariants
           fromVariants:(NSDictionary *)variants
              forAction:(NSString *)action
                context:(NSDictionary *)context
{
    SEL selector = @selector(notifyDidChoose:fromVariants:forAction:context:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didChoose:chosenVariants fromVariants:variants forAction:action context:context];
}

- (void)notifyDidRank:(NSArray *)rankedVariants
            forAction:(NSString *)action
              context:(NSDictionary *)context
{
    SEL selector = @selector(notifyDidRank:forAction:context:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didRank:rankedVariants forAction:action context:context];
}

- (void)notifyDidTrack:(NSString *)event
            properties:(NSDictionary *)properties
               context:(NSDictionary *)context
{
    SEL selector = @selector(improve:didTrack:properties:context:);
    if (!self.delegate || ![self.delegate respondsToSelector:selector]) return;

    [self.delegate improve:self didTrack:event properties:properties context:context];
}

@end
