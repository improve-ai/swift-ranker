//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeatureEncoder : NSObject

- (id)initWithModel:(double)model;

- (NSDictionary *)encode_context:(id)context withNoise:(double)noise;

- (NSDictionary *)encode_variant:(id)variant withNoise:(double)noise;

@end

NS_ASSUME_NONNULL_END
