//
//  Improve.m
//  7Second
//
//  Created by Choosy McChooseFace on 9/6/16.
//  Copyright © 2016-2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPModel.h"
#import "IMPChooser.h"
#import "NSArray+Random.h"
#import "IMPLogging.h"
#import "IMPModelMetadata.h"
#import "IMPModelDownloader.h"

@interface IMPModel ()
// Private vars

@property (strong, atomic) IMPChooser *chooser;

@end

@implementation IMPModel
@synthesize model = _model;

+ (void)modelWithContentsOfURL:(NSURL *)url
                   cacheMaxAge:(NSInteger) cacheMaxAge
             completionHandler:(void (^)(IMPModel * _Nullable model, NSError * _Nullable error))handler
{
    [[[IMPModelDownloader alloc] initWithURL:url maxAge:cacheMaxAge] downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable downloadError) {
        if (downloadError) {
            handler(nil, downloadError);
            return;
        }
       
        NSError *modelError;
        MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&modelError];
        if (modelError) {
            handler(nil, modelError);
            return;
        }
        handler([[IMPModel alloc] initWithModel:model], nil);
    }];
}

- (instancetype) initWithModel:(MLModel *) model
{
    self = [super init];
    if (!self) return nil;

    self.model = model; // call setter to set up metadata and chooser
    
    return self;
}

- (MLModel *) model
{
    @synchronized (self) {
        return _model;
    }
}

- (void) setModel:(MLModel *)model
{
    @synchronized (self) {
        _model = model;
                
        if (!model || !model.modelDescription || !model.modelDescription.metadata) {
            IMPErrLog("Invalid Improve model. model metadata not found");
            return;

        }
        NSDictionary * creatorDefined = model.modelDescription.metadata[MLModelCreatorDefinedKey];
        NSString *jsonMetadata;
        
        if (creatorDefined) {
            jsonMetadata = creatorDefined[@"json"];
        }

        if (!jsonMetadata) {
            IMPErrLog("Invalid Improve model. 'json' attribute not found");
            return;
        }
        
        IMPModelMetadata *metadata = [[IMPModelMetadata alloc] initWithString:jsonMetadata];
        if (!metadata) {
            return;
        }
        
        _modelName = metadata.model;

        _chooser = [[IMPChooser alloc] initWithModel:model metadata:metadata];
        if (!_chooser) {
            IMPErrLog("Failed to initialize Chooser!");
        }
    }
}

- (id) choose:(NSArray *) variants
{
    return [self choose:variants context:nil];
}

- (id) choose:(NSArray *) variants
      context:(nullable NSDictionary *) context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for choose variants. returning nil.");
            return nil;
        }
        
        id chosen;

        if (self.chooser) {
            chosen = [self.chooser choose:variants context:context];
        } else {
            IMPErrLog("Model not loaded.");
        }
        
        if (!chosen) {
            IMPErrLog("Choosing first variant.");
            return [variants objectAtIndex:0];
        }

        return chosen;
    }
}

- (NSArray *) sort:(NSArray *) variants
{
    return [self sort:variants context:nil];
}

- (NSArray *) sort:(NSArray *) variants
           context:(nullable NSDictionary *) context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. returning empty array");
            return @[];
        }
                
        NSArray *sorted;

        IMPChooser *chooser = [self chooser];
        if (chooser) {
            sorted = [chooser sort:variants context:context];
        } else {
            IMPErrLog("Model not loaded.");
        }
        
        if (!sorted) {
            IMPErrLog("Returning unsorted shallow copy of variants.");
            return [[NSArray alloc] initWithArray:variants];
        }

        return sorted;
    }
}

- (NSArray *)score:(NSArray *)variants
{
    return [self score:variants context:nil];
}

- (NSArray *) score:(NSArray *)variants
            context:(NSDictionary *)context
{
    @synchronized (self) {
        if (!variants || [variants count] == 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. Returning empty array");
            return @[];
        }

        IMPChooser *chooser = [self chooser];
        if (chooser) {
            return [chooser score:variants context:context];
        } else {
            IMPErrLog("Model not loaded. Returning empty array");
            return @[];
        }
    }
}

@end
