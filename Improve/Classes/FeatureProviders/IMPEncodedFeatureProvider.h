//
//  IMPEncodedFeatureProvider.h
//  ImproveUnitTests
//
//  Created by Vladimir on 3/6/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPEncodedFeatureProvider : NSObject<MLFeatureProvider>

@property(nonatomic, strong) NSDictionary<NSNumber*, NSNumber*> *dictionary;

@property(nonatomic, copy) NSString *featureNamePrefix;

@property(nonatomic, assign) NSUInteger featuresCount;

- (nullable instancetype)initWithDictionary:(NSDictionary<NSNumber*, id> *)dictionary
                                     prefix:(NSString *)prefix
                                      count:(NSUInteger)featuresCount
NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
