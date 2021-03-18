//
//  IMPDecisionModel.h
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#import "IMPDecisionTracker.h"

@class IMPDecisionModel;

typedef void (^IMPDecisionModelDownloadCompletion) (IMPDecisionModel *_Nullable compiledModelURL, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecisionModel : NSObject

@property(atomic, strong) MLModel *model;

@property(nonatomic, strong) NSString *modelName;

@property(nonatomic, strong) IMPDecisionTracker *tracker;

+ (void)loadAsync:(NSURL *)url completionHandler:(IMPDecisionModelDownloadCompletion)handler;
+ (void)loadAsync:(NSURL *)url cacheMaxAge:(NSInteger) cacheMaxAge completionHandler:(IMPDecisionModelDownloadCompletion)handler;

- (instancetype)initWithModel:(MLModel *)mlModel;

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants
             given:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
