//
//  FeatureEncoder.m
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

#import <Foundation/Foundation.h>
#import "NSDictionary+MLFeatureProvider.h"

#import "IMPFeatureEncoder.h"
#import "xxhash.h"
#import "IMPLogging.h"

#define sprinkle(x, small_noise) ((x + small_noise) * (1 + small_noise))

#define reverse_sprinkle(sprinkled, small_noise) (sprinkled / (1 + small_noise) - small_noise)

#define shrink(noise) (noise * pow(2, -17))

#define xxhash3(data, len, seed) XXH3_64bits_withSeed(data, len, seed)

@interface IMPFeatureEncoder()

@property (nonatomic) double modelSeed;

@property (strong, nonatomic) NSSet<NSString *> *modelFeatureNames;

@end

@implementation IMPFeatureEncoder{
    uint64_t _variantSeed;
    uint64_t _valueSeed;
    uint64_t _givensSeed;
}

- (instancetype)initWithModelSeed:(uint64_t)modelSeed andFeatureNames:(NSSet<NSString *> *)featureNames{
    if(self = [super init]){
        self.modelSeed = modelSeed;
        _modelFeatureNames = featureNames;
        _variantSeed = xxhash3("variant", strlen("variant"), self.modelSeed);
        _valueSeed = xxhash3("$value", strlen("$value"), _variantSeed);
        _givensSeed = xxhash3("givens", strlen("givens"), self.modelSeed);
        // NSLog(@"seeds: %llu, %llu, %llu", _variantSeed, _valueSeed, _givensSeed);
        
        _noise = NAN;
    }
    return self;
}

- (NSArray<NSDictionary *> *)encodeVariants:(NSArray<NSDictionary*> *)variants
                                      given:(nullable NSDictionary *)context {
    double noise = isnan(self.noise) ? ((double)arc4random() / UINT32_MAX) : self.noise;
    
    // if context, encode contextFeatures
    NSDictionary *contextFeatures = context ? [self encodeContext:context withNoise:noise] : nil;
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSDictionary *variant in variants) {
        NSMutableDictionary *variantFeatures = contextFeatures ? [contextFeatures mutableCopy] : [[NSMutableDictionary alloc] initWithFeatureNames:self.modelFeatureNames];
        
        [result addObject:[self encodeVariant:variant withNoise:noise forFeatures:variantFeatures]];
    }
    return result;
}

- (NSDictionary *)encodeContext:(id)context withNoise:(double)noise{
    NSMutableDictionary *features = [[NSMutableDictionary alloc] initWithFeatureNames:self.modelFeatureNames];
    double smallNoise = shrink(noise);
    return [self encodeInternal:context withSeed:_givensSeed andNoise:smallNoise forFeatures:features];
}

- (NSDictionary *)encodeVariant:(id)variant withNoise:(double)noise forFeatures:(nonnull NSMutableDictionary *)features {
    double smallNoise = shrink(noise);
    if([variant isKindOfClass:[NSDictionary class]]) {
        return [self encodeInternal:variant withSeed:_variantSeed andNoise:smallNoise forFeatures:features];
    } else {
        return [self encodeInternal:variant withSeed:_valueSeed andNoise:smallNoise forFeatures:features];
    }
}

- (NSDictionary *)encodeInternal:(id)node withSeed:(uint64_t)seed andNoise:(double)noise forFeatures:(NSMutableDictionary *)features {
    if([node isKindOfClass:[NSNumber class]]) {
        if(!isnan([node doubleValue])) {
            NSString *feature_name = [self hash_to_feature_name:seed];
            if([self.modelFeatureNames containsObject:feature_name]) {
                MLFeatureValue *curValue = [features objectForKey:feature_name];
                double unsprinkledCurValue = 0;
                if(curValue != nil) {
                    unsprinkledCurValue = reverse_sprinkle(curValue.doubleValue, noise);
                    // IMPLog("number, reverse sprinkle: %lf, %lf", [curValue doubleValue], unsprinkledCurValue);
                }
                MLFeatureValue *newValue = [MLFeatureValue featureValueWithDouble:sprinkle(unsprinkledCurValue + [node doubleValue], noise)];
                [features setObject:newValue forKey:feature_name];
            }
        }
    } else if([node isKindOfClass:[NSString class]]) {
        const char *value = [node UTF8String];
        uint64_t hashed = xxhash3(value, [node lengthOfBytesUsingEncoding:NSUTF8StringEncoding], seed);
        
        NSString *feature_name = [self hash_to_feature_name:seed];
        if([self.modelFeatureNames containsObject:feature_name]) {
            MLFeatureValue *curValue = [features objectForKey:feature_name];
            double unsprinkledCurValue = 0;
            if(curValue != nil) {
                unsprinkledCurValue = reverse_sprinkle(curValue.doubleValue, noise);
                // IMPLog("string, reverse sprinkle: %lf, %lf", [curValue doubleValue], unsprinkledCurValue);
            }
            MLFeatureValue *newValue = [MLFeatureValue featureValueWithDouble:( sprinkle(unsprinkledCurValue + ((double)((hashed & 0xffff0000) >> 16) - 0x8000), noise))];
            [features setObject:newValue forKey:feature_name];
        }
        
        NSString *hashed_feature_name = [self hash_to_feature_name:hashed];
        if([self.modelFeatureNames containsObject:hashed_feature_name]) {
            MLFeatureValue *curHashedValue = [features objectForKey:hashed_feature_name];
            double unsprinkledCurHashedValue = 0;
            if(curHashedValue != nil) {
                unsprinkledCurHashedValue = reverse_sprinkle(curHashedValue.doubleValue, noise);
                // IMPLog("hashed, reverse sprinkle: %lf, %lf", [curHashedValue doubleValue], unsprinkledCurHashedValue);
            }
            MLFeatureValue *newHashedValue = [MLFeatureValue featureValueWithDouble:(sprinkle(unsprinkledCurHashedValue+(double)(hashed & 0xffff) - 0x8000, noise))];
            [features setObject:newHashedValue forKey:hashed_feature_name];
        }
    } else if([node isKindOfClass:[NSDictionary class]]){
        [node enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            const char *value = [key UTF8String];
            uint64_t newSeed = xxhash3(value, [key lengthOfBytesUsingEncoding:NSUTF8StringEncoding], seed);
            [self encodeInternal:obj withSeed:newSeed andNoise:noise forFeatures:features];
        }];
    } else if([node isKindOfClass:[NSArray class]]){
        [node enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            unsigned char bytes[8];
            [self to_bytes:idx withBuffer:bytes];
            uint64_t newSeed = xxhash3(bytes, 8, seed);
            [self encodeInternal:obj withSeed:newSeed andNoise:noise forFeatures:features];
        }];
    } else if([node isKindOfClass:[NSNull class]]) {
        // do nothing
    } else {
        NSString *reason = [NSString stringWithFormat:@"unsupported type (%@), not JSON encodeable. Must be one of type NSArray, NSDictionary, NSString, NSNumber, Boolean, or NSNull", NSStringFromClass([node class])];
        @throw([NSException exceptionWithName:@"UnsupportedTypeException" reason:reason userInfo:nil]);
    }
    return features;
}

// int to hex string; skip leading zero
- (NSString *)hash_to_feature_name:(uint64_t)hash {
    char buffer[9] = {0};
    hash = (hash >> 32);
    const char* ref = "0123456789abcdef";
    buffer[0] = ref[((hash >> 28) & 0xf)];
    buffer[1] = ref[((hash >> 24) & 0xf)];
    buffer[2] = ref[((hash >> 20) & 0xf)];
    buffer[3] = ref[((hash >> 16) & 0xf)];
    buffer[4] = ref[((hash >> 12) & 0xf)];
    buffer[5] = ref[((hash >> 8) & 0xf)];
    buffer[6] = ref[((hash >> 4) & 0xf)];
    buffer[7] = ref[((hash) & 0xf)];
    return @(buffer);
}

// convert uint64_t to 8 bytes
- (void)to_bytes:(uint64_t)n withBuffer:(unsigned char*)buf {
    for(int i = 0; i < 8; ++i) {
        buf[i] = (n >> (7-i)*8) & 0xff;
    }
}

@end
