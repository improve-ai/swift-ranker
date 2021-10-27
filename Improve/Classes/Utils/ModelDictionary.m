//
//  ModelDictionary.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 10/26/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "ModelDictionary.h"
#import "IMPDecisionModel.h"

@interface ModelDictionary()

@property (strong, nonatomic) NSMutableDictionary<NSString *, IMPDecisionModel *> *models;

@end

@implementation ModelDictionary

- (NSMutableDictionary<NSString *, IMPDecisionModel *> *)models {
    @synchronized (self) {
        if(_models == nil) {
            _models = [[NSMutableDictionary alloc] init];
        }
    }
    return _models;
}

- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName {
    IMPDecisionModel *model = self.models[modelName];
    if(model == nil) {
        model = [[IMPDecisionModel alloc] initWithModelName:modelName];
        self.models[modelName] = model;
    }
    return model;
}

- (void)setObject:(IMPDecisionModel *)object forKeyedSubscript:(NSString *)modelName {
    self.models[modelName] = object;
}

- (NSUInteger)count {
    return [self.models count];
}

@end
