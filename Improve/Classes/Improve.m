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
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel profits:nil type:nil block:^(NSDictionary *responseBody, NSError *error) {
        if (!error) {
            block([responseBody objectForKey:key], nil);
        } else {
            block(nil, error);
        }
    }];
}

- (void)choosePriceFrom:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSNumber *, NSError *)) block
{
    [self choosePriceFrom:prices forKey:key funnel:funnel profits:nil block:block];
}

- (void)choosePriceFrom:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel profits:(NSArray *)profits block:(void (^)(NSNumber *, NSError *)) block
{
    [self chooseFrom:nil prices:prices forKey:key funnel:funnel profits:profits type:PRICE_TYPE block:^(NSDictionary *responseBody, NSError *error) {
        
        if (!error) {
            block([responseBody objectForKey:key], nil);
        } else {
            block(nil, error);
        }
    }];
}

- (void)sort:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block
{
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel profits:nil type:SORT_TYPE block:^(NSDictionary *responseBody, NSError *error) {
        
        if (!error) {
            block([responseBody objectForKey:key], nil);
        } else {
            block(nil, error);
        }
    }];
}


- (void)chooseFrom:(NSArray *)choices prices:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel profits:(NSArray *)profits type:(NSString*)type block:(void (^)(NSDictionary *, NSError *)) block
{
    
    NSDictionary *body = @{ @"property_key": key,
                            @"funnel": funnel,
                            @"user_id": _userId};
    
    if (choices) {
        [body setValue:choices forKey:@"choices"];
    }
    
    if (prices) {
        [body setValue:prices forKey:@"prices"];
    }
    
    if (profits) {
        [body setValue:profits forKey:@"profits"];
    }
    
    if (type) {
        [body setValue:type forKey:@"type"];
    }
    
    [self sendRequestTo:CHOOSE_URL body:body block:block];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{

    NSDictionary *body = @{ @"event": event,
                            @"properties": properties,
                            @"user_id": _userId };
    
    [self sendRequestTo:TRACK_URL body:body block:^(NSDictionary *responseBody, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        } 
    }];
}

- (void) sendRequestTo:(NSString *) url body:(NSDictionary *) body block:(void (^)(NSDictionary *, NSError *)) block {
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
                    error = [NSError errorWithDomain:@"Improve" code:statusCode userInfo:[(NSHTTPURLResponse *) response allHeaderFields]];
                }
            }
            
            NSDictionary *dictionary;
            
            if (!error) {
                // convert the NSData response to a dictionary
                // a parse error is a possibility
                dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }
            
            if (error) { // transport, HTTP, or parse error
                block(nil, error);
            } else {
                // success!
                block(dictionary, nil);
            }
        }];
    [dataTask resume];
}
@end
