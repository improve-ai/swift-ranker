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

- (instancetype)init {
    if(self = [super init]) {
        _models = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName {
    IMPDecisionModel *model;
    @synchronized (self) {
        model = self.models[modelName];
        if(model == nil) {
            model = [[IMPDecisionModel alloc] initWithModelName:modelName];
            self.models[modelName] = model;
        } else {
            model = self.models[modelName];
        }
    }
    return model;
}

- (void)setObject:(IMPDecisionModel *)model forKeyedSubscript:(NSString *)modelName {
    @synchronized (self) {
        if(model != nil && ![model.modelName isEqualToString:modelName]) {
            NSString *reason = [NSString stringWithFormat:@"modelName(%@) must be equal to model.modelName(%@)", modelName, model.modelName];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
        self.models[modelName] = model;
    }
}

- (NSUInteger)count {
    @synchronized (self) {
        return [self.models count];
    }
}

- (void)clear {
    @synchronized (self) {
        [self.models removeAllObjects];
    }
}

@end
