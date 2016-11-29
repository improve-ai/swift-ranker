//
//  Improve.h
//  7Second
//
//  Created by Justin Chapweske on 9/8/16.
//  Copyright © 2016 Impressive Sounding, LLC. All rights reserved.
//
@interface Improve : NSObject

@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSString *userId;

+ (Improve *)sharedInstance;

+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey;
+ (Improve *)sharedInstanceWithApiKey:(NSString *)apiKey userId:(NSString *)userId;


- (void)track:(NSString *)event properties:(NSDictionary *)properties;



- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSString *, NSError *)) block;

// For example, to choose the best price call
// [self chooseFrom:prices forKey:key withRewards:prices block:block];

- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel rewards:(NSArray *)rewards block:(void (^)(NSString *, NSError *)) block;

- (void)sort:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel block:(void (^)(NSArray *, NSError *)) block;

- (void)chooseFrom:(NSArray *)choices forKey:(NSString *)key funnel:(NSArray *)funnel rewards:(NSArray *)rewards type:(NSString*)type block:(void (^)(NSDictionary *, NSError *)) block;

@end

