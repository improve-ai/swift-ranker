//
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(DecisionTracker)
@interface IMPDecisionTracker : NSObject

// TODO
// trackURL and trackApiKey used to be declared as 'atomic', why?
@property(nonatomic, strong) NSURL *trackURL;

@property(nonatomic, copy) NSString *trackApiKey;

/**
 Hyperparameter that affects training speed and model performance. Values from 10-100 are probably reasonable.  0 disables runners up tracking
 */
@property(atomic) NSUInteger maxRunnersUp;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithTrackURL:(NSURL *)trackURL trackApiKey:(nullable NSString *)trackApiKey NS_SWIFT_NAME(init(_:_:));

- (void)addReward:(double)reward forModel:(NSString *)modelName;

- (void)addReward:(double)reward forModel:(NSString *)modelName decision:(NSString *)decisionId;

- (nullable NSString *)track:(NSArray *)rankedVariants given:(NSDictionary *)givens modelName:(NSString *)modelName;

- (NSString *)track:(id)variant givens:(nullable NSDictionary *)givens runnersUp:(nullable NSArray *)runnersUp sample:(nullable id)sample variantCount:(NSUInteger)variantCount modelName:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END
