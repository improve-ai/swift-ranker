//
//  IMPDecisionTracker.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecisionTracker : NSObject

@property(atomic, strong) NSURL *trackURL;

@property(atomic, strong, nullable) NSString *apiKey;

/// Hyperparameter that affects training speed and model performance. Values from 10-100 are probably reasonable.
@property(atomic) NSUInteger maxRunnersUp;

- (instancetype)initWithTrackURL:(NSURL *)trackURL;

- (instancetype)initWithTrackURL:(NSURL *)trackURL
                          apiKey:(nullable NSString *)apiKey;

- (void)trackEvent:(NSString *)event;

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties;

- (void)trackEvent:(NSString *)event
        properties:(nullable NSDictionary *)properties
           context:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
