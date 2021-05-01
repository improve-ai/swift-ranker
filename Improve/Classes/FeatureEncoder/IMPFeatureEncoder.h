//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeatureEncoder : NSObject

// Added for unit test
@property (nonatomic) BOOL testMode;

// Added for unit test.
// when testMode is YES, this noise value is used instead of a randomly generated one.
@property (nonatomic) double noise;

- (instancetype)initWithModelSeed:(uint64_t)modelSeed andFeatureNames:(NSSet<NSString *> *)featureNames;

- (NSArray<NSDictionary *> *)encodeVariants:(NSArray<NSDictionary*> *)variants
                                      given:(nullable NSDictionary *)context;
@end

NS_ASSUME_NONNULL_END
