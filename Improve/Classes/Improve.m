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
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel type:nil block:block];
}

- (void)chooseFrom:(NSURLRequest *)choicesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSObject *, NSError *)) block
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
    [self chooseFrom:nil prices:prices forKey:key funnel:funnel type:nil block:block];
}

- (void)choosePriceFrom:(NSURLRequest *)pricesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSNumber *, NSError *)) block
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
    [self chooseFrom:choices prices:nil forKey:key funnel:funnel type:SORT_TYPE block:block];
}

- (void)sort:(NSURLRequest *)choicesRequest forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block
{
    [self fetchRemoteArray:choicesRequest block:^(NSArray *result, NSError *error) {
        if (result && !error) {
            [self sort:result forKey:key funnel:funnel block:block];
        } else {
            block(nil,error);
        }
    }];
}

- (void)chooseFrom:(NSArray *)choices prices:(NSArray *)prices forKey:(NSString *)key funnel:(NSArray *)funnel type:(NSString*)type block:(void (^)(NSObject *, NSError *)) block
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
    
    [self sendRequestTo:TRACK_URL body:body block:^(NSObject *result, NSError *error) {
        if (error) {
            NSLog(@"Improve.track error: %@", error);
        } 
    }];
}

- (void) fetchRemoteArray:(NSURLRequest *) request block:(void (^)(NSArray *, NSError *)) block {
    
}

- (void) sendRequestTo:(NSString *) url body:(NSDictionary *) body block:(void (^)(NSObject *, NSError *)) block {
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
            /*
             NSError *jsonError = nil;
             id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:&jsonError];
             
             if ([jsonObject isKindOfClass:[NSArray class]]) {
             NSLog(@"its an array!");
             NSArray *jsonArray = (NSArray *)jsonObject;
             NSLog(@"jsonArray - %@",jsonArray);
             }
             else {
             NSLog(@"its probably a dictionary");
             NSDictionary *jsonDictionary = (NSDictionary *)jsonObject;
             NSLog(@"jsonDictionary - %@",jsonDictionary);
             }*/
            
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
                block([responseBody objectForKey:key], nil);
            }
        }];
    [dataTask resume];
}
@end
