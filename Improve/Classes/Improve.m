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

#define CHOOSE_URL @"https://api.improve.ai/v3/choose"
#define USING_URL @"https://api.improve.ai/v3/using"
#define REWARDS_URL @"https://api.improve.ai/v3/rewards"

#define USER_ID_KEY @"ai.improve.user_id"

@implementation Improve : NSObject

static Improve *sharedInstance;

+ (Improve *)instanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithApiKey:apiKey userId:userId];
    });
    return sharedInstance;
}

+ (Improve *)instanceWithApiKey:(NSString *)apiKey
{
    return [Improve instanceWithApiKey:apiKey userId:nil];
}

+ (Improve *)instance
{
    return sharedInstance;
}

- (instancetype)initWithApiKey:(NSString *)apiKey userId:(NSString *)userId
{
    self.apiKey = apiKey;
    if (!userId) {
        self.userId = [[NSUserDefaults standardUserDefaults] stringForKey:USER_ID_KEY];
        if (!self.userId) {
            // create a UUID if one isn't provided
            self.userId = [[NSUUID UUID] UUIDString];
            [[NSUserDefaults standardUserDefaults] setObject:self.userId forKey:USER_ID_KEY];
        }
    } else {
        self.userId = userId;
    }
    
    _chooseUrl = CHOOSE_URL;
    _usingUrl = USING_URL;
    _rewardsUrl = REWARDS_URL;
    
    _propertiesByModel = [NSMutableDictionary dictionary];
    _contextByModel = [NSMutableDictionary dictionary];
    _usingByModel = [NSMutableDictionary dictionary];
    
    return self;
}

- (void)chooseRemote:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey };
    
    
    NSMutableDictionary *body = [@{ @"variants": variants,
                                    @"model": modelName,
                                    @"user_id": _userId } mutableCopy];

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

- (NSDictionary *)choose:(NSDictionary *)variants
                   model:(NSString *)modelName
                 context:(NSDictionary *)context
{
    NSURL *modelURL = [NSBundle.mainBundle URLForResource:modelName withExtension:@"mlmodelc"];
    if (!modelURL) {
      NSLog(@"Model not found: %@.mlmodelc", modelName);
        return [self chooseRandom:variants context:context];
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelURL:modelURL error:&error];
    if (!chooser) {
        NSLog(@"%@", error);
        return [self chooseRandom:variants context:context];
    }

    NSDictionary *properties = [chooser choose:variants context:context];
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

- (void) setVariants:(NSDictionary *)variants model:(NSString *)model context:(NSDictionary *)context {
    if ([_propertiesByModel objectForKey:model]) {
        NSLog(@"Improve.setVariants: Overwriting properties for model %@ not allowed, ignoring", model);
        return;
    }
    // Loop through the variants, temporarily storing the first variant for each property in case
    // the /choose call is slow or fails
    NSMutableDictionary *tmpProperties = [NSMutableDictionary dictionary];
    for (id key in variants) {
        NSArray *variantValues = [variants objectForKey:key];
        if ([variantValues isKindOfClass:[NSArray class]] && [variantValues count] >= 1) {
            [tmpProperties setObject:variantValues[0] forKey:key];
        }
    }
    // This also takes care of setting the context
    [self setProperties:tmpProperties model:model context:context];
    
    // fire off the request to /choose
    [self chooseRemote:variants model:model context:context completion:^(NSDictionary *properties, NSError *error) {
        if (error) {
            NSLog(@"Improve.setVariants error: %@, using defaults", error);
            return;
        }
        
        // Overwrite the temp properties with the answer from /choose
        [_propertiesByModel setObject:properties forKey:error];
    }];
}

- (void) setProperties:(NSDictionary *)properties model:(NSString *)model context:(NSDictionary *)context  {
    if ([_propertiesByModel objectForKey:model]) {
        NSLog(@"Improve.setProperties: Overwriting properties for model %@ not allowed, ignoring", model);
        return;
    }
    [_propertiesByModel setObject:properties forKey:model];
    [_contextByModel setObject:context forKey:model];
}

- (NSDictionary *) propertiesForModel:(NSString *)model {

    if (![_propertiesByModel objectForKey:model]) {
        NSLog(@"Improve.propertiesForModel: No properties set for model %@, returning empty properties going forward", model);
        // Set it to an empty dictionary so that its not overwritten in setProperties:
        [_propertiesByModel setObject:@{} forKey:model];
        // Don't send a /using request to improve.ai
        [_usingByModel setObject:@TRUE forKey:model];
    }

    NSDictionary *properties = [_propertiesByModel objectForKey:model];
    
    // Track using once
    if (![_usingByModel objectForKey:model]) {
        [_usingByModel setObject:@TRUE forKey:model];
        [self trackUsing:properties model:model context:[_contextByModel objectForKey:model]];
    }
    
    return properties;
}

- (void) trackUsing:(NSDictionary *)properties model:(NSString *)modelName context:(NSDictionary *)context
{
    [self trackUsing:properties model:modelName context:context rewardKey:nil];
}

- (void) trackUsing:(NSDictionary *)properties model:(NSString *)modelName context:(NSDictionary *)context rewardKey:(NSString *)rewardKey
{
    
    if (!properties) {
        properties = @{};
    }
    
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey };
    
    // required variables
    NSMutableDictionary *body = [@{ @"model": modelName,
                                    @"properties": properties,
                                    @"user_id": _userId } mutableCopy];
    
    if (context) {
        [body setObject:context forKey:@"context"];
    }
    if (rewardKey) {
        [body setObject:rewardKey forKey:@"reward_key"];
    }
    
    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        NSLog(@"Improve.track error: %@", err);
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_usingUrl]];
    
    [request setHTTPMethod:@"POST"];
    [request setAllHTTPHeaderFields:headers];
    [request setHTTPBody:postData];
    
    [self postImproveRequest:request block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        }
    }];
}

- (void) trackRevenue:(NSNumber *)revenue receipt:(NSData *)receipt
{
    [self trackRevenue:revenue receipt:receipt currency:nil];
}

- (void) trackRevenue:(NSNumber *)revenue receipt:(NSData *)receipt currency:(NSString *)currency
{
    [self trackRewards:@{ @"revenue": revenue } receipt:receipt currency:currency];
}

- (void) trackRewards:(NSDictionary *)rewards
{
    [self trackRewards:rewards receipt:nil currency:nil];
}

- (void) trackRewards:(NSDictionary *)rewards receipt:(NSData *)receipt currency:(NSString *)currency
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey};
    
    
    NSMutableDictionary *body = [@{ @"rewards": rewards,
                                    @"user_id": _userId } mutableCopy];
    
    if (receipt) {
        [body setObject:[receipt base64EncodedStringWithOptions:0] forKey:@"receipt"];
    }
    
    if (currency) {
        [body setObject:currency forKey:@"currency"];
    }
    
    NSError * err;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    if (err) {
        NSLog(@"Improve.track error: %@", err);
        return;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_rewardsUrl]];
    
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
@end
