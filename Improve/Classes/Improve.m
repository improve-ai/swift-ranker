//
//  Improve.m
//  7Second
//
//  Created by Justin Chapweske on 9/6/16.
//  Copyright © 2016-2017 Impressive Sounding, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Improve.h"

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
    
    return self;
}

- (void)choose:(NSDictionary *)variants model:(NSString *)modelName context:(NSDictionary *)context completion:(void (^)(NSDictionary *, NSError *)) block
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

- (void) trackRevenue:(NSNumber *)revenue
{
    [self trackRevenue:revenue currency:nil];
}

- (void) trackRevenue:(NSNumber *)revenue currency:(NSString *)currency
{
    [self trackRewards:@{ @"revenue": revenue } currency:currency];
}

- (void) trackRewards:(NSDictionary *)rewards
{
    [self trackRewards:rewards currency:nil];
}

- (void) trackRewards:(NSDictionary *)rewards currency:(NSString *)currency
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey};
    
    
    NSMutableDictionary *body = [@{ @"rewards": rewards,
                                    @"user_id": _userId } mutableCopy];
    
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
             The response from choose looks like this:
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
