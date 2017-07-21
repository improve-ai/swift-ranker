//
//  ImproveAI.m
//  7Second
//
//  Created by Justin Chapweske on 9/6/16.
//  Copyright © 2016 Impressive Sounding, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Improve.h"

#define TRACK_URL @"https://api.improve.ai/v1/track"
#define CONFIGURE_URL @"https://api.improve.ai/v1/configure"

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
    
    _trackUrl = TRACK_URL;
    _configureUrl = CONFIGURE_URL;
    
    return self;
}


- (void) improveConfiguration:(NSURLRequest *)fetchRequest block:(void (^)(NSDictionary *, NSError *)) block
{
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    // fetch the improve.yml file
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:fetchRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!block) {
            return;
        }
        
        if (!error && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            
            if (statusCode >= 400) {
                error = [NSError errorWithDomain:@"ai.improve" code:statusCode userInfo:[(NSHTTPURLResponse *) response allHeaderFields]];
            }
        }

        if (error) { // transport or HTTP error
            block(nil, error);
            return;
        }
        
        NSDictionary *headers = @{ @"Content-Type": @"application/x-yaml",
                                   @"x-api-key":  _apiKey,
                                   @"x-user-id": _userId};
        
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:_configureUrl]];
        
        [request setHTTPMethod:@"POST"];
        [request setAllHTTPHeaderFields:headers];
        [request setHTTPBody:data];

        // post improve.yml back to /configure
        [self postImproveRequest:request block:^(NSObject *response, NSError *error) {
            if (error) {
                block(nil, error);
            } else {
                /*
                 The response from configure looks like this:
                 {
                   "properties": {
                     key: "value"
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
    }];
    [dataTask resume];
}

- (void)track:(NSString *)event properties:(NSDictionary *)properties
{
    
    NSDictionary *headers = @{ @"Content-Type": @"application/json",
                               @"x-api-key":  _apiKey};


    NSDictionary *body = @{ @"event": event,
                            @"properties": properties,
                            @"user_id": _userId };
    
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
