//
//  IMPScoredVariant.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/27/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPScoredVariant : NSObject

@property(nonatomic) double score;

@property(strong, nonatomic) id variant;

+ (instancetype)withScore:(double)score variant:(id)variant;

- (instancetype)initWithScore:(double)score variant:(id)variant;

@end

NS_ASSUME_NONNULL_END
