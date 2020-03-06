//
//  IMPMurmurHash.m
//  FeatureHasher
//
// Based on: https://github.com/mzsanford/murmurhashforiios/tree/master/murmurhashforios/murmurhashforios

#import "IMPMurmurHash.h"
#import "MurmurHash3.h"

@implementation IMPMurmurHash

+ (uint32_t)hash32:(NSString *)input withSeed:(uint32_t)seed
{
    const char* str = [input UTF8String];
    int len = (int)[input length];
    void* buff[32/8];
    MurmurHash3_x86_32(str, len, seed, buff);
    uint32_t result = ((uint32_t*)buff)[0];
    return result;
}

+ (uint64_t)hash64:(NSString *)input withSeed:(uint32_t)seed
{
    const char* str = [input UTF8String];
    int len = (int)[input length];
    void* buff[128/8]; // 128 bit buffer
    MurmurHash3_x86_128(str,len,seed,buff);
    // take out lowest 64 bits from buff, ignore upper 64 bit
    uint64_t result = ((uint64_t*)buff)[0];
    return result;
}

+ (uint32_t)hash32:(NSString *)input {
    return [self hash32:input withSeed:0];
}

+ (uint64_t)hash64:(NSString *)input {
    return [self hash64:input withSeed:0];
}

/*
-(void) hash128:(NSString*)input result:(Hash128Result*)result {
    const char* str = [input UTF8String];
    int len = [input length];
    //uint32_t hash;
    void* buff[128/8]; // 128 bit buffer
    MurmurHash3_x86_128(str,len,0,buff);
    result->lower64bit = ((uint64_t*)buff)[0];
    result->upper64bit = ((uint64_t*)buff)[1];
}
*/

@end
