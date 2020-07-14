//
//  IMPScoredObject.h
//  ImproveUnitTests
//
//  Created by Vladimir on 2/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPScoredObject : NSObject

@property(nonatomic) double score;

@property(strong, nonatomic) id object;

+ (instancetype)withScore:(double)score object:(id)object;

- (instancetype)initWithScore:(double)score object:(id)object;

@end

NS_ASSUME_NONNULL_END
