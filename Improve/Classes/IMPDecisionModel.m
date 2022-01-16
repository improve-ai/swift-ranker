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
#import "IMPDecisionContext.h"
#import "NSDictionary+MLFeatureProvider.h"
#import "IMPUtils.h"
#import "IMPDecisionTracker.h"
#import "AppGivensProvider.h"
#import "IMPConstants.h"

@interface IMPDecisionModel ()
// Private vars

@property (strong, atomic) IMPFeatureEncoder *featureEncoder;

@property (nonatomic) BOOL enableTieBreaker;

@property (strong, atomic) IMPDecisionTracker *tracker;

@end

@implementation IMPDecisionModel

@synthesize trackURL = _trackURL;
@synthesize trackApiKey = _trackApiKey;
@synthesize model = _model;

static NSURL * _defaultTrackURL;

static NSString * _defaultTrackApiKey;

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

+ (NSString *)defaultTrackApiKey
{
    return _defaultTrackApiKey;
}

+ (void)setDefaultTrackApiKey:(NSString *)defaultTrackApiKey {
    _defaultTrackApiKey = defaultTrackApiKey;
}

+ (ModelDictionary *)instances
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [[ModelDictionary alloc] init];
    });
    return _instances;
}

+ (GivensProvider *)defaultGivensProvider
{
    return [AppGivensProvider shared];
}

- (instancetype)initWithModelName:(NSString *)modelName
{
    return [self initWithModelName:modelName trackURL:_defaultTrackURL trackApiKey:_defaultTrackApiKey];
}

- (instancetype)initWithModelName:(NSString *)modelName trackURL:(NSURL *)trackURL trackApiKey:(nullable NSString *)trackApiKey
{
    if(self = [super init]) {
        _enableTieBreaker = YES;
        if([self isValidModelName:modelName]) {
            _modelName = [modelName copy];
        } else {
            NSString *reason = [NSString stringWithFormat:@"invalid model name: [%@]", modelName];
            @throw [NSException exceptionWithName:NSInvalidArgumentException
                                           reason:reason
                                         userInfo:nil];
        }
        
        if(trackURL) {
            _trackURL = trackURL;
            _tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL trackApiKey:trackApiKey];
        }
        
        _trackApiKey = [trackApiKey copy];
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
    if(trackURL != nil) {
        self.tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL trackApiKey:self.trackApiKey];;
    } else {
        self.tracker = nil;
    }
}

- (NSString *)trackApiKey
{
    return _trackApiKey;
}

- (void)setTrackApiKey:(NSString *)trackApiKey
{
    _trackApiKey = [trackApiKey copy];
    if(self.tracker != nil) {
        self.tracker.trackApiKey = trackApiKey;
    }
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

        if(![_modelName isEqualToString:modelName]) {
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
            if(downloadError) {
                if(handler) handler(nil, downloadError);
                return;
            }

            NSError *modelError;
            MLModel *model = [MLModel modelWithContentsOfURL:compiledModelURL error:&modelError];
            if(modelError) {
                if(handler) handler(nil, modelError);
                return;
            }
            
            self.model = model;
            
            if(handler) handler(self, nil);
        });
    }];
}

- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    return [[[IMPDecisionContext alloc] initWithModel:self andGivens:nil] chooseFrom:variants];
}

- (IMPDecision *)chooseMultiVariate:(NSDictionary<NSString *, id> *)variants {
    return [[[IMPDecisionContext alloc] initWithModel:self andGivens:nil] chooseMultiVariate:variants];
}

- (id)which:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    id variant = [self which:firstVariant args:args];
    va_end(args);
    return variant;
}

- (id)which:(id)firstVariant args:(va_list)args NS_SWIFT_NAME(which(_:_:))
{
    return [[[IMPDecisionContext alloc] initWithModel:self andGivens:nil] which:firstVariant args:args];
}

- (IMPDecisionContext *)given:(NSDictionary <NSString *, id>*)givens
{
    return [[IMPDecisionContext alloc] initWithModel:self andGivens:givens];
}

- (void)addReward:(double) reward
{
    if(_tracker == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"trackURL can't be nil when calling addReward()" userInfo:nil];
    }
    [_tracker addReward:reward forModel:self.modelName];
}

// Add reward for a specific tracked decision
- (void)addReward:(double)reward decision:(NSString *)decisionId {
    if(_tracker == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"trackURL can't be nil when calling addReward()" userInfo:nil];
    }
    [_tracker addReward:reward forModel:self.modelName decision:decisionId];
}

- (NSArray <NSNumber *>*)score:(NSArray *)variants
{
    NSDictionary *givens = nil;
    GivensProvider *givensProvider = self.givensProvider;
    if(givensProvider != nil) {
        givens = [givensProvider givensForModel:self givens:nil];
    }
    return [self scoreInternal:variants given:givens];
}

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @param givens Additional context info that will be used with each of the variants to calcuate the score
 * @return scores of the variants
 */
- (NSArray <NSNumber *>*)scoreInternal:(NSArray *)variants
              given:(nullable NSDictionary <NSString *, id>*)givens
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        if ([variants count] <= 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants can't be empty or nil" userInfo:nil];
        }
#ifdef IMPROVE_AI_DEBUG
        IMPLog("givens: %@", givens);
#endif
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
            if(self.enableTieBreaker) {
                // add a very small random number to randomly break ties
                val += ((double)arc4random() / UINT32_MAX) * pow(2, -23);
            }
            [scores addObject:@(val)];
        }
#ifdef IMPROVE_AI_DEBUG
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[a-zA-Z0-9][\\w\\-.]{0,63}$"];
    return [predicate evaluateWithObject:modelName];
}

@end
