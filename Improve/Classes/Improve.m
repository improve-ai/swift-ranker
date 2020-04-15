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

#define CHOOSE_URL @"https://api.improve.ai/v3/choose"
#define TRACK_URL @"https://api.improve.ai/v3/track"


@interface IMPConfiguration ()
- (NSURL *) modelURLForName:(NSString *)modelName;
@end


@interface Improve ()
// Private vars

@property (nonatomic, strong) NSString *chooseUrl;

@property (nonatomic, strong) NSString *trackUrl;

@property (strong, nonatomic) IMPConfiguration *configuration;

/// Already loaded models
@property (strong, nonatomic)
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

    _chooseUrl = CHOOSE_URL;
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
                    model:(NSString *)modelName
                  context:(NSDictionary *)context
{
    IMPChooser *chooser = [self chooserForModelWithName:modelName];
    if (!chooser) {
        return [self chooseRandom:variants context:context];
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

- (void)chooseRemote:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block
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

    [self postChooseRequest:headers data:postData block:block];
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
    [self track:bodyValues];
}

- (void) track:(NSDictionary *)bodyValues
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key": self.apiKey };

    // required variables
    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);
    // Example: 2020-02-03T03:16:36.073Z
    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];
    NSMutableDictionary *body = [@{ @"user_id": self.userId,
                                    @"timestamp": dateStr,
                                    @"history_id": self.configuration.historyId
                                   } mutableCopy];
    [body addEntriesFromDictionary:bodyValues];

    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        NSLog(@"Improve.track error: %@", err);
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_trackUrl]];

    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];

    [self postImproveRequest:request block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        }
    }];
}

- (void) postChooseRequest:(NSDictionary *)headers data:(NSData *)postData block:(void (^)(NSDictionary *, NSError *)) block
{
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_chooseUrl]];
    
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
                            model:(NSString *)modelName
                          context:(NSDictionary *)context
{
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
    return rankedVariants;
}

- (NSArray<NSDictionary*> *) rankAllPossible:(NSDictionary<NSString*, NSArray*> *)variantMap
                                       model:(NSString *)modelName
                                     context:(NSDictionary *)context
{
    NSArray<NSDictionary*> *combinations = [self combinationsFromVariants:variantMap];
    NSArray<NSDictionary*> *ranked = [self rank:combinations model:modelName context:context];
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

// Load models one by one
- (void)loadModelsForConfiguration:(IMPConfiguration *)configuration
{
    void (^loadModelAtIndex) (NSUInteger);
    loadModelAtIndex = ^(NSUInteger modelIndex) {
        if (modelIndex >= configuration.modelNames.count) return;

        NSString *modelName = configuration.modelNames[modelIndex];
        modelIndex++;

        [self loadModelForName:modelName
                 configuration:configuration
                    completion:^(BOOL isLoaded) {
            if (isLoaded) {
                // load next
                loadModelAtIndex(modelIndex + 1);
            } else {
                // reload
                loadModelAtIndex(modelIndex);
            }
        }];
    };
}

// Load model or use the cached one if possible
- (void)loadModelForName:(NSString *)name
           configuration:(IMPConfiguration *)configuration
              completion:(nullable void(^)(BOOL isLoaded))completion
{
    NSURL *url = [configuration modelURLForName:name];

    if (self.downloader)
    {
        if ([self.downloader.modelName isEqualToString:name]
            && self.downloader.isLoading) {
            // Allready loading - do nothing
            return;
        } else {
            // Only one download at time supported
            [self.downloader cancel];
        }
    }

    self.downloader = [[IMPModelDownloader alloc] initWithURL:url modelName:name];
    IMPModelBundle *cached = self.downloader.cachedBundle;
    NSTimeInterval staleAge = configuration.modelStaleAge;
    if (cached && [[NSDate now] timeIntervalSinceDate:cached.creationDate] > staleAge) {
        self.modelBundlesByName[name] = cached;
        if (completion) completion(YES);
        return;
    }

    __weak Improve *weakSelf = self;
    [self.downloader loadWithCompletion:^(IMPModelBundle *bundle, NSError *error) {
        BOOL isLoaded = false;

        if (error) {
            NSLog(@"Model loading error: %@", error);
        }
        if (bundle) {
            weakSelf.modelBundlesByName[name] = bundle;
            isLoaded = YES;
        }

        if (completion) completion(isLoaded);
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
                        model:(NSString *)modelName
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
                        model:(NSString *)modelName
                      context:(NSDictionary *)context
             chosenProperties:(NSDictionary *)properties
{
    return [self calculatePropensity:variants
                               model:modelName
                             context:context
                    chosenProperties:properties
                      iterationCount:9];
}

@end
