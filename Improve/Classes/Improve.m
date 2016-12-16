//
//  ImproveAI.m
//  7Second
//
//  Created by Justin Chapweske on 9/6/16.
//  Copyright © 2016 Impressive Sounding, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Improve.h"

#define SORT_TYPE @"sort"

#define CHOOSE_URL @"https://api.improve.ai/v1/choose"
#define TRACK_URL @"https://api.improve.ai/v1/track"

#define USER_ID_KEY @"ai.improve.user_id"


@implementation Improve : NSObject

static Improve *sharedInstance;
+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithApiKey:apiKey userId:userId];
    });
    return sharedInstance;
}

+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey
{
    return [Improve sharedInstanceWithApiKey:apiKey userId:nil];
}

+ (Improve *)sharedInstance
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
    return self;
}

- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSObject *, NSError *)) block
{
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel sort:false block:block];
}

- (void)chooseFromRemote:(NSURLRequest *)choicesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSObject *, NSError *)) block
{
    [self fetchRemoteArray:choicesRequest block:^(NSArray *result, NSError *error) {
        if (result && !error) {
            [self chooseFrom:result forKey:key funnel:funnel block:block];
        } else {
            block(nil,error);
        }
    }];
}

- (void)choosePriceFrom:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSNumber *, NSError *)) block
{
    [self chooseFrom:nil prices:prices forKey:key funnel:funnel sort:false block:^(NSObject *result, NSError *error) {
        if (result) {
            block(result, error);
        } else {
            block(nil,error);
        }
    }];

}

- (void)choosePriceFromRemote:(NSURLRequest *)pricesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSNumber *, NSError *)) block
{
    [self fetchRemoteArray:pricesRequest block:^(NSArray *result, NSError *error) {
        if (result && !error) {
            [self choosePriceFrom:result forKey:key funnel:funnel block:block];
        } else {
            block(nil,error);
        }
    }];
}

- (void)sort:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block
{
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel sort:true block:^(NSObject *result, NSError *error) {
        if (result) {
            block(result, error);
        } else {
            block(nil,error);
        }
    }];
}

- (void)sortFromRemote:(NSURLRequest *)choicesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block
{
    [self fetchRemoteArray:choicesRequest block:^(NSArray *result, NSError *error) {
        if (result && !error) {
            [self sort:result forKey:key funnel:funnel block:block];
        } else {
            block(nil,error);
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
    
    [self postImproveRequest:CHOOSE_URL body:body block:^(NSObject *response, NSError *error) {
        if (error) {
            block(nil, error);
        } else if (![response isKindOfClass:[NSDictionary class]]) {
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"expected dictionary, got %@", response]}]);
        } else {
            // Extract the value from the dictionary
            block([(NSDictionary *)response objectForKey:key], nil);
        }
    }];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{

    NSDictionary *body = @{ @"event": event,
                            @"properties": properties,
                            @"user_id": _userId };
    
    [self postImproveRequest:TRACK_URL body:body block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        } 
    }];
}

- (void) fetchRemoteArray:(NSURLRequest *) request block:(void (^)(NSArray *, NSError *)) block
{
    [self fetchJson:request block:^(NSObject *response, NSError *error) {
        if (error) {
            block(nil, error);
        } else if (![response isKindOfClass:[NSArray class]]) {
            block(nil, [NSError errorWithDomain:@"ai.improve" code:400 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"expected array, got %@", response]}]);
        } else {
            block(response, nil);
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
    
    [self fetchJson:request block:block];
}

/*
 Fetch and parse the JSON response accessible via the NSURLRequest.  Since the caller sets up the requests it could be a full blown POST or a simple GET.
 The callback is executed on the main thread.
 */
- (void) fetchJson:(NSURLRequest *) request block:(void (^)(NSObject *, NSError *)) block {
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
