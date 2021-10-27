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

/**
 * Models are automatically created using the provided name, for example DecisionModel.instances[‘greetings’] always
 * returns a DecisionModel(‘greetings’), even if it was not previously set.  Previously returned models are cached.
 * Models can be overwritten with DecisionModel.instances[‘greetings’] = newModel.  Shared models can be cleared with
 * DecisionModel.instances[‘greetings’] = nil
 */
- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName;

- (void)setObject:(nullable IMPDecisionModel *)object forKeyedSubscript:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END


