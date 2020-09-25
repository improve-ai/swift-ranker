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

/**
 Custom API key for tracking. Methods like `-trackDecision:` and `-addReward:` are authorised with this key.
 */
@property (atomic, strong, nullable) NSString *trackApiKey;

/**
 Custom API gateway for tracking. Data from `-trackDecision:` and  `-addReward:` will be posted to that URL.
 */
@property (atomic, strong, nullable) NSString *trackUrl;

@property (atomic, assign) BOOL autoTrackDecisions;

@end

NS_ASSUME_NONNULL_END
