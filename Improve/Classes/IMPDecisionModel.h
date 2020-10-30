//
//  IMPDecisionModel.h
//  ImproveUnitTests
//
//  Created by Vladimir on 10/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

@class IMPDecisionModel;

typedef void (^IMPDecisionModelDownloadCompletion) (IMPDecisionModel *_Nullable compiledModelURL, NSError *_Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface IMPDecisionModel : NSObject

@property(nonatomic, strong) NSString *name;

@property(atomic, strong) MLModel *model;

+ (void)modelWithContentsOfURL:(NSURL *)url
                   cacheMaxAge:(NSInteger) cacheMaxAge
             completionHandler:(IMPDecisionModelDownloadCompletion)handler;

- (instancetype)initWithModel:(MLModel *)mlModel;

/**
 Takes an array of variants and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *)score:(NSArray *)variants
           context:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
