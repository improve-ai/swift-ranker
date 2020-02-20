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
#define TRACK_URL @"https://api.improve.ai/v3/track"

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

- (NSDictionary *)choose:(NSDictionary *)variants
                   model:(NSString *)modelName
                 context:(NSDictionary *)context
{

    NSURL *modelURL = [NSBundle.mainBundle URLForResource:modelName withExtension:@"mlmodelc"];
    if (!modelURL) {
        NSLog(@"Improve.choose: Model not found: %@.mlmodelc", modelName);
        return [self chooseRandom:variants context:context];
    }

    NSError *error = nil;
    IMPChooser *chooser = [IMPChooser chooserWithModelURL:modelURL error:&error];
    if (!chooser) {
        NSLog(@"Improve.choose: %@", error);
        return [self chooseRandom:variants context:context];
    }

    NSDictionary *properties = [chooser choose:variants context:context];

    /*
     TODO:
     model_id (need model.json)
     propensity (need propensity calculation)
     */
    NSDictionary *trackData = @{
        @"type": @"choose",
        @"model": modelName,
        @"variants": variants,
        @"context": context,
        @"chosen": properties
    };
    [self track:trackData];

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
                               @"x-api-key":  _apiKey };

    // required variables
    NSISO8601DateFormatOptions options = (NSISO8601DateFormatWithInternetDateTime
                                          | NSISO8601DateFormatWithFractionalSeconds
                                          | NSISO8601DateFormatWithTimeZone);
    // Example: 2020-02-03T03:16:36.073Z
    NSString *dateStr = [NSISO8601DateFormatter stringFromDate:[NSDate date]
                                                      timeZone:[NSTimeZone localTimeZone]
                                                 formatOptions:options];
    NSMutableDictionary *body = [@{ @"user_id": _userId,
                                    @"timestamp": dateStr } mutableCopy];
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
@end
