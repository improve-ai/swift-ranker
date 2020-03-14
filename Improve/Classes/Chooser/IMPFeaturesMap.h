//
//  IMPFeaturesMap.h
//  ImproveUnitTests
//
//  Created by Vladimir on 3/12/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeaturesMap : NSObject

/// Key is property_key and value is an array of dictionaries {property_key: variant} for each possible variant.
@property(strong, nonatomic) NSDictionary<NSString*, NSArray*> *partialTrials;

/// Key is property_key and value is a a features dictionary for each variant.
@property(strong, nonatomic) NSDictionary<NSString*, NSArray*> *partialFeatures;

@property(strong, nonatomic) NSDictionary<NSString*, id> *context;

@property(strong, nonatomic) NSDictionary<NSNumber*, NSNumber*> *contextFeatures;

@end

NS_ASSUME_NONNULL_END
