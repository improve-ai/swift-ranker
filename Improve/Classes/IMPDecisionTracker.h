//
//  IMPDecisionTracker.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionTracker)
@interface IMPDecisionTracker : NSObject

@property(atomic, strong) NSURL *trackURL;

@property(atomic, strong, nullable) NSString *apiKey;

/// Hyperparameter that affects training speed and model performance. Values from 10-100 are probably reasonable.
@property(atomic) NSUInteger maxRunnersUp;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTrackURL:(NSURL *)trackURL NS_SWIFT_NAME(init(_:));

- (instancetype)initWithTrackURL:(NSURL *)trackURL
                          apiKey:(nullable NSString *)apiKey NS_SWIFT_NAME(init(_:_:));

- (void)trackEvent:(NSString *)eventName;

- (void)trackEvent:(NSString *)eventName
        properties:(nullable NSDictionary *)properties;

@end

NS_ASSUME_NONNULL_END
