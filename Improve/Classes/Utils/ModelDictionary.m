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

@property (strong, nonatomic) dispatch_queue_t readWriteQueue;

@end

@implementation ModelDictionary

- (instancetype)init {
    if(self = [super init]) {
        _models = [[NSMutableDictionary alloc] init];
        _readWriteQueue = dispatch_queue_create("ai.improve.models", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (IMPDecisionModel *)objectForKeyedSubscript:(NSString *)modelName {
    __block IMPDecisionModel *model = nil;
    dispatch_sync(self.readWriteQueue, ^{
        model = self.models[modelName];
        if(model == nil) {
            model = [[IMPDecisionModel alloc] initWithModelName:modelName];
            self.models[modelName] = model;
        }
    });
    return model;
}

- (void)setObject:(IMPDecisionModel *)model forKeyedSubscript:(NSString *)modelName {
    dispatch_barrier_async(self.readWriteQueue, ^{
        if(model != nil && ![model.modelName isEqualToString:modelName]) {
            NSString *reason = [NSString stringWithFormat:@"modelName(%@) must be equal to model.modelName(%@)", modelName, model.modelName];
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:reason userInfo:nil];
        }
        self.models[modelName] = model;
    });
}

- (NSUInteger)count {
    __block NSUInteger c = 0;
    dispatch_sync(self.readWriteQueue, ^{
        c = [self.models count];
    });
    return c;
}

- (void)clear {
    dispatch_barrier_async(self.readWriteQueue, ^{
        [self.models removeAllObjects];
    });
}

@end
