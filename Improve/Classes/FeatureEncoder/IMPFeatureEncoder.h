//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeatureEncoder : NSObject

- (id)initWithModelSeed:(uint64_t)modelSeed;

- (NSDictionary *)encodeContext:(id)context withNoise:(double)noise;

- (NSDictionary *) encodeVariant:(id)variant withNoise:(double)noise forFeatures:(NSMutableDictionary *)features;

@end

NS_ASSUME_NONNULL_END
