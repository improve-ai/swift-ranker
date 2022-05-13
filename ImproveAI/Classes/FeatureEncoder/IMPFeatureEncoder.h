//
//  FeatureEncoder.h
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPFeatureEncoder : NSObject

@property (nonatomic) double noise;

- (instancetype)initWithModelSeed:(uint64_t)modelSeed andFeatureNames:(NSSet<NSString *> *)featureNames;

- (NSArray<id<MLFeatureProvider>> *)encodeVariants:(NSArray *)variants given:(nullable NSDictionary *)context;
@end

NS_ASSUME_NONNULL_END
