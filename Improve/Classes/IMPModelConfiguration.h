//
//  IMPModelConfiguration.h
//  ImproveUnitTests
//
//  Created by Justin Chapweske on 9/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelConfiguration : NSObject

+ (IMPModelConfiguration *) configuration;

/**
 Custom API gateway for tracking. Data from `-trackDecision:` and  `-addReward:` will be posted to that URL.
 */
@property (atomic, strong, nullable) NSString *trackUrl;

/**
 Custom API key for tracking. Methods like `-trackDecision:` and `-addReward:` are authorised with this key.
 */
@property (atomic, strong, nullable) NSString *trackApiKey;

/**
 The maximum number of seconds a downloaded model can be cached
 */
@property (atomic, assign) NSInteger cacheMaxAge;

/**
 Whether or not to automatically track decisions in choose.  Note: decisions are never automatically tracked in sort.
 */
@property (atomic, assign) BOOL autoTrackChooseDecisions;

@end

NS_ASSUME_NONNULL_END
