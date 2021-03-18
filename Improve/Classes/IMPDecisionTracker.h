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

@property(atomic, strong) NSURL *trackURL;

@property(atomic, strong, nullable) NSString *apiKey;

/// Hyperparameter that affects training speed and model performance. Values from 10-100 are probably reasonable.
@property(atomic) NSUInteger maxRunnersUp;

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

/**
 Track a passive observation of a variant.  This method does not provide necessary counterfactual information on non-chosen variants, so it is STRONGLY recommended to instead use -trackUsingBestFromDecision: whenever possible.  Passive observations are only intended to supplement training data in cases where it is difficult to track full Decisions.  Training a model based solely on passive observations is likely to lead to biased models.
 */
- (id)trackUsingVariant:(id)variant
              modelName:(NSString *)modelName
                context:(NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
