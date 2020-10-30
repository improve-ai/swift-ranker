//
//  IMPDecisionTracker.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMPDecision;

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecisionTracker : NSObject

@property(nonatomic, strong) NSURL *trackURL;

@property(nonatomic, strong, nullable) NSString *apiKey;

- (instancetype)initWithTrackURL:(NSURL *)trackURL;

- (instancetype)initWithTrackURL:(NSURL *)trackURL
                          apiKey:(nullable NSString *)apiKey;

- (id)trackUsingBestFromDecision:(IMPDecision *)decision;

- (void)trackEvent:(NSString *)event;

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties;

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties
           context:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
