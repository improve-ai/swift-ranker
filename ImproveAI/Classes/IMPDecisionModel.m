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
#import "IMPJSONUtils.h"
#import "IMPDecisionTracker.h"
#import "AppGivensProvider.h"
#import "IMPConstants.h"

@interface IMPDecisionContext()

- (instancetype)initWithModel:(IMPDecisionModel *)model andGivens:(nullable NSDictionary *)givens;

- (id)firstInternal:(NSArray *)variants;

- (id)randomInternal:(NSArray *)variants;

@end

@interface IMPDecision ()

//@property (nonatomic, copy) NSArray *variants;

@property (nonatomic, copy, nullable) NSDictionary *givens;

@property(nonatomic, strong) id best;

- (instancetype)initWithModel:(IMPDecisionModel *)model NS_SWIFT_NAME(init(_:));

@end

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
@synthesize givensProvider = _givensProvider;

static NSURL * _defaultTrackURL;

static NSString * _defaultTrackApiKey;

static IMPModelDictionary *_instances;

static IMPGivensProvider *_defaultGivensProvider;

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

+ (IMPModelDictionary *)instances
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instances = [[IMPModelDictionary alloc] init];
    });
    return _instances;
}

+ (IMPGivensProvider *)defaultGivensProvider
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

// TODO: If givensProvider is set as nil explicitly, should the default givens provider be used anyway?
- (IMPGivensProvider *)givensProvider
{
    @synchronized (self) {
        return _givensProvider ? _givensProvider : IMPDecisionModel.defaultGivensProvider;
    }
}

- (void)setGivensProvider:(IMPGivensProvider *)givensProvider {
    @synchronized (self) {
        _givensProvider = givensProvider;
    }
}

- (NSURL *)trackURL
{
    @synchronized (self) {
        return _trackURL;
    }
}

- (void)setTrackURL:(NSURL *)trackURL
{
    @synchronized (self) {
        _trackURL = trackURL;
        if(trackURL != nil) {
            _tracker = [[IMPDecisionTracker alloc] initWithTrackURL:trackURL trackApiKey:_trackApiKey];;
        } else {
            _tracker = nil;
        }
    }
}

- (NSString *)trackApiKey
{
    @synchronized (self) {
        return _trackApiKey;
    }
}

- (void)setTrackApiKey:(NSString *)trackApiKey
{
    @synchronized (self) {
        _trackApiKey = [trackApiKey copy];
        if(_tracker != nil) {
            _tracker.trackApiKey = trackApiKey;
        }
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
        
        NSString *versionString = creatorDefined[@"ai.improve.version"];
        if(![self canParseVersion:versionString]) {
            NSString *reason = [NSString stringWithFormat:@"Major version of ImproveAI SDK(%@) and extracted model version(%@) don't match!", kIMPVersion, versionString];
            @throw [NSException exceptionWithName:@"InvalidModelVersion" reason:reason userInfo:nil];
        }
        
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

- (instancetype)load:(NSURL *)url error:(NSError **)error
{
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
            
            @try {
                self.model = model;
            } @catch(NSException *e) {
                NSError *error = [NSError errorWithDomain:@"ai.improve.IMPDecisionModel" code:-100 userInfo:@{NSLocalizedDescriptionKey:e.reason}];
                if(handler) handler(nil, error);
                return;
            }
            
            if(handler) handler(self, nil);
        });
    }];
}

- (IMPDecisionContext *)given:(NSDictionary <NSString *, id>*)givens
{
    return [[IMPDecisionContext alloc] initWithModel:self andGivens:givens];
}

- (NSArray <NSNumber *>*)score:(NSArray *)variants
{
    NSDictionary *givens = nil;
    IMPGivensProvider *givensProvider = self.givensProvider;
    if(givensProvider != nil) {
        givens = [givensProvider givensForModel:self givens:nil];
    }
    return [self scoreInternal:variants allGivens:givens];
}

- (IMPDecision *)decide:(NSArray *)variants
{
    return [self decide:variants ordered:false];
}

- (IMPDecision *)decide:(NSArray *)variants ordered:(BOOL)ordered
{
    return [[self given:nil] decide:variants ordered:ordered];
}

- (IMPDecision *)decide:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores
{
    return [[self given:nil] decide:variants scores:scores];
}

- (id)which:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    if([variants count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"which() expects at least one argument." userInfo:nil];
    }
    return [self whichFrom:variants];
}

- (id)whichFrom:(NSArray *)variants
{
    return [[self given:nil] whichFrom:variants];
}

- (NSArray *)rank:(NSArray *)variants
{
    return [[self given:nil] rank:variants];
}

- (id)optimize:(NSDictionary<NSString *, id> *)variantMap
{
    return [[self given:nil] optimize:variantMap];
}

- (NSArray *)fullFactorialVariants:(NSDictionary *)variantMap
{
    if([variantMap count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variantMap can't be nil or empty." userInfo:nil];
    }
    
    NSMutableArray *keys = [[NSMutableArray alloc] initWithCapacity:[variantMap count]];
    
    NSMutableArray *categories = [NSMutableArray arrayWithCapacity:[variantMap count]];
    [variantMap enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if(![obj isKindOfClass:[NSArray class]]) {
            [categories addObject:@[obj]];
            [keys addObject:key];
        } else {
            // ignore empty array values
            if([obj count] > 0) {
                [categories addObject:obj];
                [keys addObject:key];
            }
        }
    }];
    
    NSMutableArray<NSDictionary *> *combinations = [[NSMutableArray alloc] init];
    for(int i = 0; i < [categories count]; ++i) {
        NSArray *category = categories[i];
        NSMutableArray<NSDictionary *> *newCombinations = [[NSMutableArray alloc] init];
        for(int m = 0; m < [category count]; ++m) {
            if([combinations count] == 0) {
                [newCombinations addObject:@{keys[i]:category[m]}];
            } else {
                for(int n = 0; n < [combinations count]; ++n) {
                    NSMutableDictionary *newVariant = [combinations[n] mutableCopy];
                    [newVariant setObject:category[m] forKey:keys[i]];
                    [newCombinations addObject:newVariant];
                }
            }
        }
        combinations = newCombinations;
    }
    
    return combinations;
}

- (void)addReward:(double) reward
{
    IMPDecisionTracker *tracker = self.tracker;
    if(tracker == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"trackURL can't be nil when calling addReward()" userInfo:nil];
    }
    [tracker addReward:reward forModel:self.modelName];
}

// Add reward for a specific tracked decision
- (void)addReward:(double)reward decision:(NSString *)decisionId
{
    IMPDecisionTracker *tracker = self.tracker;
    if(tracker == nil) {
        @throw [NSException exceptionWithName:IMPIllegalStateException reason:@"trackURL can't be nil when calling addReward()" userInfo:nil];
    }
    [tracker addReward:reward forModel:self.modelName decision:decisionId];
}

#pragma mark - Deprecated, remove in 8.0

- (IMPDecision *)chooseFrom:(NSArray *)variants
{
    return [[self given:nil] chooseFrom:variants];
}

- (IMPDecision *)chooseFrom:(NSArray *)variants scores:(NSArray<NSNumber *> *)scores
{
    return [[self given:nil] chooseFrom:variants scores:scores];
}

- (IMPDecision *)chooseFirst:(NSArray *)variants
{
    return [[self given:nil] chooseFirst:variants];
}

- (id)first:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    return [[self given:nil] firstInternal:variants];
}

- (id)first:(NSInteger)n args:(va_list)args
{
    return [[self given:nil] first:n args:args];
}

- (IMPDecision *)chooseRandom:(NSArray *)variants
{
    return [[self given:nil] chooseRandom:variants];
}

- (id)random:(id)firstVariant, ...
{
    va_list args;
    va_start(args, firstVariant);
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(id arg = firstVariant; arg != nil; arg = va_arg(args, id)) {
        [variants addObject:arg];
    }
    va_end(args);
    return [[self given:nil] randomInternal:variants];
}

- (id)random:(NSInteger)n args:(va_list)args
{
    return [[self given:nil] random:n args:args];
}

- (IMPDecision *)chooseMultivariate:(NSDictionary<NSString *, id> *)variants
{
    return [[self given:nil] chooseMultivariate:variants];
}

/**
 * @param variants Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries,
 *  arrays, strings, numbers, nulls, and booleans.
 * @param allGivens Additional context info that will be used with each of the variants to calcuate the score, including the givens passed in
 * through DecisionModel.given(givens) and the givens provided by the AppGivensProvider or other custom GivensProvider.
 * @return scores of the variants
 */
- (NSArray <NSNumber *>*)scoreInternal:(NSArray *)variants
              allGivens:(nullable NSDictionary <NSString *, id>*)allGivens
{
    // MLModel is not thread safe, synchronize
    @synchronized (self) {
        if ([variants count] <= 0) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants can't be nil or empty." userInfo:nil];
        }
#ifdef IMPROVE_AI_DEBUG
        IMPLog("givens: %@", [IMPJSONUtils jsonStringOrDescriptionOf:allGivens]);
#endif
        if(self.model == nil) {
            // When tracking a decision like this:
            // IMPDecisionModel *model = [[IMPDecisionModel alloc] initWithModelName:@"model"];
            // [[model chooseFrom:variants] get];
            // The model is not loaded. In this case, we return the scores quietly
            // without logging an error.
            return [IMPDecisionModel generateDescendingGaussians:variants.count];
        }

        NSArray *encodedFeatures = [_featureEncoder encodeVariants:variants given:allGivens];
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
    if(([variants count] != [scores count]) || ([variants count] <= 0)) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants can't be nil or empty, and variants.count must equal scores.count" userInfo:nil];
    }
    NSUInteger count = variants.count > scores.count ? variants.count : scores.count;
    double bestScore = -DBL_MAX;
    id bestVariant = nil;
    for (NSInteger i = 0; i < count; i++) {
        double score = [scores[i] doubleValue];
        if (score > bestScore) {
            bestScore = score;
            bestVariant = variants[i];;
        }
    }

    return bestVariant;
}

// Case 3 #2 refsort approach: https://stackoverflow.com/a/27309301
+ (NSArray *)rank:(NSArray *)variants withScores:(NSArray <NSNumber *>*)scores
{
    if([variants count] <= 0 || [scores count] <= 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants and scores can't be nil or empty" userInfo:nil];
    }
    
    if([variants count] != [scores count]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"variants.count must equal scores.count" userInfo:nil];
    }
    
    NSUInteger size = [variants count];
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
+ (NSArray *)generateDescendingGaussians:(NSUInteger) count
{
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; ++i){
        [arr addObject:[NSNumber numberWithDouble:[IMPUtils gaussianNumber]]];
    }
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 doubleValue] < [obj2 doubleValue];
    }];
    return [arr copy];
}

+ (NSArray *)generateRandomScores:(NSUInteger)count {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; ++i){
        [arr addObject:[NSNumber numberWithDouble:[IMPUtils gaussianNumber]]];
    }
    return [arr copy];
}

- (BOOL)isValidModelName:(NSString *)modelName {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[a-zA-Z0-9][\\w\\-.]{0,63}$"];
    return [predicate evaluateWithObject:modelName];
}

- (BOOL)canParseVersion:(NSString *)versionString {
    if(versionString == nil) {
        return YES;
    }
    NSArray<NSString *> *array = [kIMPVersion componentsSeparatedByString:@"."];
    NSString *prefix = [NSString stringWithFormat:@"%@.", array[0]];
    return [versionString hasPrefix:prefix] || [versionString isEqualToString:array[0]];
}

@end
