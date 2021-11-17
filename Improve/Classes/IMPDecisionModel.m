//
//  IMPDecisionModel.m
//
//  Created by Justin Chapweske on 3/17/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPDecisionModel.h"
#import "NSArray+Random.h"
#import "IMPLogging.h"
#import "IMPFeatureEncoder.h"
#import "IMPModelDownloader.h"
#import "IMPDecision.h"
#import "NSDictionary+MLFeatureProvider.h"
#import "IMPUtils.h"
#import "IMPDecisionTracker.h"
#import "AppGivensProvider.h"

@interface IMPDecisionModel ()
// Private vars

@property (strong, atomic) IMPFeatureEncoder *featureEncoder;

@property (strong, atomic) IMPDecisionTracker *tracker;

@end

@implementation IMPDecisionModel

@synthesize trackURL = _trackURL;
@synthesize model = _model;

static NSURL * _defaultTrackURL;

static ModelDictionary *_instances;

static GivensProvider *_defaultGivensProvider;

+ (NSURL *)defaultTrackURL
{
    return _defaultTrackURL;
}

+ (void)setDefaultTrackURL:(NSURL *)defaultTrackURL
{
    _defaultTrackURL = defaultTrackURL;
}

+ (ModelDictionary *)instances {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [[ModelDictionary alloc] init];
    });
    return _instances;
}

+ (GivensProvider *)defaultGivensProvider {
    return [AppGivensProvider shared];
}

- (instancetype)initWithModelName:(NSString *)modelName
{
    return [self initWithModelName:modelName trackURL:_defaultTrackURL];
}

- (instancetype)initWithModelName:(NSString *)modelName trackURL:(NSURL *)trackURL
{
    if(self = [super init]) {
        if([self isValidModelName:modelName]) {
            _modelName = modelName;
        } else {
            NSString *reason = [NSString stringWithFormat:@"invalid model name: [%@]", modelName];
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
        }
        
        if(trackURL) {
            _trackURL = trackURL;
            _tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL];
        }
    }
    return self;
}

- (GivensProvider *)givensProvider
{
    return _givensProvider ? _givensProvider : IMPDecisionModel.defaultGivensProvider;
}

- (NSURL *)trackURL
{
    return _trackURL;
}

- (void)setTrackURL:(NSURL *)trackURL
{
    _trackURL = trackURL;
    _tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL];
}

- (MLModel *) model
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        return _model;
    }
}

- (void) setModel:(MLModel *)model
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        _model = model;

        if (!model || !model.modelDescription || !model.modelDescription.metadata) {
            IMPErrLog("Invalid Improve model. model metadata not found");
            return;

        }
        NSDictionary * creatorDefined = model.modelDescription.metadata[MLModelCreatorDefinedKey];
        
        NSString *modelName = creatorDefined[@"ai.improve.model.name"];
        if([modelName length] <= 0) {
            IMPErrLog("Invalid Improve model: modelName is nil or empty");
            return ;
        }
        
        NSString *seedString = creatorDefined[@"ai.improve.model.seed"];
        uint64_t seed = strtoull([seedString UTF8String], NULL, 0);

        if(_modelName == nil) {
            _modelName = modelName;
        } else if(![_modelName isEqualToString:modelName]) {
            // The modelName set before loading the model has higher priority than
            // the one extracted from the model file. Just print a warning here if
            // they don't match.
            IMPErrLog("Model names don't match: current model name is [%@]; "
                      "model name extracted is [%@]. [%@] will be used.", _modelName, modelName, _modelName);
        }
        
        NSSet *featureNames = [[NSSet alloc] initWithArray:_model.modelDescription.inputDescriptionsByName.allKeys];

        _featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:seed andFeatureNames:featureNames];
    }
}

- (instancetype)load:(NSURL *)url error:(NSError **)error {
    __block NSError *blockError = nil;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self loadAsync:url completion:^(IMPDecisionModel * _Nullable compiledModel, NSError * _Nullable err) {
        blockError = err;
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    if(error) {
        *error = blockError;
    }

    return blockError ? nil : self;
}

- (void)loadAsync:(NSURL *)url completion:(void (^)(IMPDecisionModel *_Nullable loadedModel, NSError *_Nullable error))handler
{
    [[[IMPModelDownloader alloc] initWithURL:url] downloadWithCompletion:^(NSURL * _Nullable compiledModelURL, NSError * _Nullable downloadError) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (downloadError) {
                if (handler) handler(nil, downloadError);
                return;
            }

            NSError *modelError;
            MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&modelError];
            if (modelError) {
                handler(nil, modelError);
                return;
            }
            
            self.model = model;
            
            handler(self, nil);
        });
    }];
}


- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    return [[[IMPDecision alloc] initWithModel:self] chooseFrom:variants];
}


- (IMPDecision *)given:(NSDictionary <NSString *, id>*)givens
{
    IMPDecision *decision = [[IMPDecision alloc] initWithModel:self];
    decision.givens = givens;
    return decision;
}

- (void)addReward:(double) reward
{
    if(_tracker != nil) {
        [_tracker addReward:reward forModel:self.modelName];
        
        // _tracker.addReward() would thrown an exception in case of
        // an invalid reward. We should call AppGivensProvider.addReward()
        // after _tracker.addReward()
        [AppGivensProvider addReward:reward forModel:self.modelName];
    }
}

- (NSArray <NSNumber *>*)score:(NSArray *)variants
{
    return [self score:variants given:nil];
}

- (NSArray <NSNumber *>*)score:(NSArray *)variants
              given:(nullable NSDictionary <NSString *, id>*)givens
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        if ([variants count] <= 0) {
            IMPErrLog("Non-nil, non-empty array required for sort variants. Returning empty array");
            return @[];
        }
        
        if(self.model == nil) {
            // When tracking a decision like this:
            // IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"model"];
            // [[model chooseFrom:variants] get];
            // The model is not loaded. In this case, we return the scores quietly
            // without logging an error.
            return [IMPDecisionModel generateDescendingGaussians:variants.count];
        }

        NSArray *encodedFeatures = [_featureEncoder encodeVariants:variants given:givens];
        MLArrayBatchProvider *batchProvider = [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:encodedFeatures];

        NSError *error = nil;
        id<MLBatchProvider> prediction = [self.model predictionsFromBatch:batchProvider
                                                                  options:[MLPredictionOptions new]
                                                                    error:&error];
        if (!prediction) {
            IMPErrLog("MLModel.predictionsFromBatch error: %@ returning variants scored in descending order", error);
            // assign gaussian scores for the variants in descending order
            return [IMPDecisionModel generateDescendingGaussians:variants.count];
        }

        NSMutableArray *scores = [NSMutableArray arrayWithCapacity:prediction.count];
        for (NSUInteger i = 0; i < prediction.count; i++) {
            double val = [[prediction featuresAtIndex:i] featureValueForName:@"target"].doubleValue;
            val += ((double)arc4random() / UINT32_MAX) * pow(2, -23); // add a very small random number to randomly break ties
            [scores addObject:@(val)];
        }
#ifdef IMP_DEBUG
        [IMPUtils dumpScores:scores andVariants:variants];
#endif
        return scores;
    }
}


// in case of tie, the lowest index wins. Ties should be very rare due to small random noise added to scores
// in IMPChooser.score()
+ (id)topScoringVariant:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores
{
    NSUInteger count = variants.count > scores.count ? variants.count : scores.count;
    double bestScore = -DBL_MAX;
    id bestVariant = nil;
    for (NSInteger i = 0; i < count; i++) {
        double score = [scores[i] doubleValue];
        id variant = variants[i];
        if (score > bestScore)
        {
            bestScore = score;
            bestVariant = variant;
//            bestVariant = variants[i];
        }
    }

    return bestVariant;
}


// If variants.count != scores.count, an NSRangeException exception will be thrown.
// Case 3 #2 refsort approach: https://stackoverflow.com/a/27309301
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores
{
    NSUInteger size;
    if(variants.count > scores.count) {
        size = variants.count;
    } else {
        size = scores.count;
    }
    NSMutableArray<NSNumber *> *indices = [[NSMutableArray alloc] initWithCapacity:size];
    for(NSUInteger i = 0; i < size; ++i){
        indices[i] = [NSNumber numberWithInteger:i];
    }
    
    // sort descending
    [indices sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return scores[[obj1 unsignedIntValue]].doubleValue < scores[[obj2 unsignedIntValue]].doubleValue;
    }];
    
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:variants.count];
    for(NSUInteger i = 0; i < indices.count; ++i){
        result[i] = variants[indices[i].intValue];
    }
    
    return result;
}

    
// Generate n = variants.count random (double) gaussian numbers
// Sort the numbers descending and return the sorted list
// The median value of the list is expected to have a score near zero
+ (NSArray *)generateDescendingGaussians:(NSUInteger) count {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; ++i){
        [arr addObject:[NSNumber numberWithDouble:[IMPUtils gaussianNumber]]];
    }
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 doubleValue] < [obj2 doubleValue];
    }];
    return [arr copy];
}

- (BOOL)isValidModelName:(NSString *)modelName {
    if(modelName == nil) {
        return YES;
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[a-zA-Z0-9][\\w\\-.]{0,63}$"];
    return [predicate evaluateWithObject:modelName];
}

@end
