//
//  FeatureEncoder.m
//  PyF
//
//  Created by PanHongxi on 3/10/21.
//

#import <Foundation/Foundation.h>

#import "IMPFeatureEncoder.h"
#import "xxhash.h"

#define sprinkle(x, small_noise) ((x + small_noise) * (1 + small_noise))

#define shrink(noise) (noise * pow(2, -17))

#define xxhash3(data, len, seed) XXH3_64bits_withSeed(data, len, seed)

@interface IMPFeatureEncoder()

@property (nonatomic) double model;

@end

@implementation IMPFeatureEncoder{
    uint64_t _variant_seed;
    uint64_t _value_seed;
    uint64_t _context_seed;
}

- (id)initWithModel:(double)model{
    if(self = [super init]){
        self.model = model;
        _variant_seed = xxhash3("variant", strlen("variant"), self.model);
        _value_seed = xxhash3("$value", strlen("$value"), _variant_seed);
        _context_seed = xxhash3("context", strlen("context"), self.model);
    }
    return self;
}

- (NSDictionary *)encode_context:(id)context withNoise:(double)noise{
    NSMutableDictionary<NSString*, NSNumber*> *features = [[NSMutableDictionary alloc] init];
    double shrinkedNoise = shrink(noise);
    return [self encode_internal:context withSeed:_context_seed andNoise:shrinkedNoise forFeature:features];
}

- (NSDictionary *)encode_variant:(id)variant withNoise:(double)noise{
    NSMutableDictionary<NSString*, NSNumber*> *features = [[NSMutableDictionary alloc] init];
    
    double small_noise = shrink(noise);
    
    if([variant isKindOfClass:[NSDictionary class]]){
        return [self encode_internal:variant withSeed:_variant_seed andNoise:small_noise forFeature:features];
    } else {
        return [self encode_internal:variant withSeed:_value_seed andNoise:small_noise forFeature:features];
    }
}

- (NSDictionary *)encode_internal:(id)context withSeed:(uint64_t)seed andNoise:(double)noise forFeature:(NSMutableDictionary *)features{
    if([context isKindOfClass:[NSNumber class]]){
        NSString *feature_name = [self hash_to_feature_name:seed];
        NSNumber *curValue = [features objectForKey:feature_name];
        NSNumber *newValue = [NSNumber numberWithDouble:([curValue doubleValue] + sprinkle([context doubleValue], noise))];
        [features setObject:newValue forKey:feature_name];
    } else if([context isKindOfClass:[NSString class]]){
        const char *value = [context UTF8String];
        uint64_t hashed = xxhash3(value, strlen(value), seed);
        
        NSString *feature_name = [self hash_to_feature_name:seed];
        NSNumber *curValue = [features objectForKey:feature_name];
        NSNumber *newValue = [NSNumber numberWithDouble:([curValue doubleValue] + sprinkle((double)((hashed & 0xffff0000) >> 16) - 0x8000, noise))];
        [features setObject:newValue forKey:feature_name];
        NSString *hashed_feature_name = [self hash_to_feature_name:hashed];
        NSNumber *curHashedValue = [features objectForKey:hashed_feature_name];
        NSNumber *newHashedValue = [NSNumber numberWithDouble:([curHashedValue doubleValue] + sprinkle((double)(hashed & 0xffff) - 0x8000, noise))]; // the double type cast here cannot be omitted. Guess why?
        [features setObject:newHashedValue forKey:hashed_feature_name];
    } else if([context isKindOfClass:[NSDictionary class]]){
        [context enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            const char* ckey = [key UTF8String];
            uint64_t newSeed = xxhash3(ckey, strlen(ckey), seed);
            [self encode_internal:obj withSeed:newSeed andNoise:noise forFeature:features];
        }];
    } else if([context isKindOfClass:[NSArray class]]){
        [context enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            unsigned char bytes[8];
            [self to_bytes:idx withBuffer:bytes];
            uint64_t newSeed = xxhash3(bytes, 8, seed);
            [self encode_internal:obj withSeed:newSeed andNoise:noise forFeature:features];
        }];
    }
    return features;
}

- (NSString *)hash_to_feature_name:(uint64_t)hash{
    char buffer[12];
    sprintf(buffer, "%x", (uint32_t)(hash>>32));
    return @(buffer);
}

// convert uint64_t to 8 bytes
- (void)to_bytes:(uint64_t)n withBuffer:(unsigned char*)buf{
    for(int i = 0; i < 8; ++i){
        buf[i] = (n >> (7-i)*8) & 0xff;
    }
}

@end
