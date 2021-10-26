//
//  ModelDictionary.h
//  Tests
//
//  Created by PanHongxi on 10/26/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

@interface ModelDictionary : NSObject

- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName;

- (void)setObject:(nullable IMPDecisionModel *)object forKeyedSubscript:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END


