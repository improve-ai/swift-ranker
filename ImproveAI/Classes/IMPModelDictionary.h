//
//  IMPModelDictionary.h
//  Tests
//
//  Created by PanHongxi on 10/26/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IMPDecisionModel;

NS_ASSUME_NONNULL_BEGIN

@interface IMPModelDictionary : NSObject

/**
 * Models are automatically created using the provided name, for example DecisionModel.instances[‘greetings’] always
 * returns a DecisionModel(‘greetings’), even if it was not previously set.  Previously returned models are cached.
 * Models can be overwritten with DecisionModel.instances[‘greetings’] = newModel.  Shared models can be cleared with
 * DecisionModel.instances[‘greetings’] = nil.
 * @param modelName Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
 * are allowed in the modenName and the first character must be an alphnumeric one.
 */
- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName;

/**
 * @exception NSInvalidArgumentException if modelName is nil, or when model != nil and model.modelName != modelName
 */
- (void)setObject:(nullable IMPDecisionModel *)model forKeyedSubscript:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END


