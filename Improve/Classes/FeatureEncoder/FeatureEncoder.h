//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

#ifndef FeatureEncoder_h
#define FeatureEncoder_h

@interface FeatureEncoder : NSObject

- (id)initWithModel:(double)model;

- (NSDictionary *)encode_context:(id)context withNoise:(double)noise;

- (NSDictionary *)encode_variant:(id)variant withNoise:(double)noise;

@end

#endif /* FeatureEncoder_h */
