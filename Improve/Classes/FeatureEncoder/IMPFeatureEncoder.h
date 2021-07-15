//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeatureEncoder : NSObject

@property (nonatomic) double noise;

- (instancetype)initWithModelSeed:(uint64_t)modelSeed andFeatureNames:(NSSet<NSString *> *)featureNames;

- (NSArray<NSDictionary *> *)encodeVariants:(NSArray<NSDictionary*> *)variants
                                      given:(nullable NSDictionary *)context;
@end

NS_ASSUME_NONNULL_END
