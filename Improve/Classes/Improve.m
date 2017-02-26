//
//  ImproveAI.m
//  7Second
//
//  Created by Justin Chapweske on 9/6/16.
//  Copyright © 2016 Impressive Sounding, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Improve.h"

#define CHOOSE_URL @"https://api.improve.ai/v1/choose"
#define TRACK_URL @"https://api.improve.ai/v1/track"

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
    _trackUrl = TRACK_URL;
    
    return self;
}

- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSObject *, NSError *)) block
{
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel sort:false block:block];
}

- (void)choosePriceFrom:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSNumber *, NSError *)) block
{
    [self chooseFrom:nil prices:prices forKey:key funnel:funnel sort:false block:^(NSObject *result, NSError *error) {
        if (error) {
            block(nil, error);
        } else if (![result isKindOfClass:[NSNumber class]]) {
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"expected NSNumber, got %@", result]}]);
        } else {
            block((NSNumber *)result, nil);
        }
    }];

}

- (void)sort:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block
{
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel sort:true block:^(NSObject *result, NSError *error) {
        if (error) {
            block(nil, error);
        } else if (![result isKindOfClass:[NSArray class]]) {
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"expected NSArray, got %@", result]}]);
        } else {
            block((NSArray *)result, nil);
        }
    }];
}


- (void)chooseFrom:(NSArray *)choices prices:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel sort:(BOOL)sort block:(void (^)(NSObject *, NSError *)) block
{
    
    NSMutableDictionary *body = [@{ @"property_key": key,
                                    @"funnel": funnel,
                                    @"user_id": _userId}
                                 mutableCopy];
    
    if (choices) {
        body[@"choices"] = choices;
    }
    
    if (prices) {
        body[@"prices"] = prices;
    }
    
    if (sort) {
        body[@"sort"] = @YES;
    }
    
    [self postImproveRequest:_chooseUrl body:body block:^(NSObject *response, NSError *error) {
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
                    // extract the value
                    NSObject *propertyValue = [(NSDictionary *)properties objectForKey:key];
                    if (propertyValue) {
                        block(propertyValue, nil);
                        return;
                    }
                }
            }
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"malformed response from choose: %@", response]}]);
        }
    }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{

    NSDictionary *body = @{ @"event": event,
                            @"properties": properties,
                            @"user_id": _userId };
    
    [self postImproveRequest:_trackUrl body:body block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        } 
    }];
}


- (void) postImproveRequest:(NSString *) url body:(NSDictionary *) body block:(void (^)(NSObject *, NSError *)) block
{
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey};
    
    NSError * err;
    NSData * postData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&err];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
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
                    error = [NSError errorWithDomain:@"ai.improve" code:statusCode userInfo:[(NSHTTPURLResponse *) response allHeaderFields]];
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
