//
//  IMPMurmurHash.h
//  FeatureHasher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPMurmurHash : NSObject

+ (uint32_t)hash32:(NSString *)input;
+ (uint64_t)hash64:(NSString *)input;

@end

NS_ASSUME_NONNULL_END
