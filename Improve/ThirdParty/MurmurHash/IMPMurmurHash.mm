//
//  IMPMurmurHash.m
//  FeatureHasher
//
// Based on: https://github.com/mzsanford/murmurhashforiios/tree/master/murmurhashforios/murmurhashforios

#import "IMPMurmurHash.h"
#import "MurmurHash3.h"

@implementation IMPMurmurHash

+ (uint32_t)hash32:(NSString *)input {
    const char* str = [input UTF8String];
    int len = (int)[input length];
    //uint32_t hash;
    void* buff[32/8]; // 128 bit buffer
    MurmurHash3_x86_32(str, len, 0, buff);
    // take out lowest 64 bits from buff, ignore upper 64 bit
    uint32_t result = ((uint32_t*)buff)[0];
    return result;
}

+ (uint64_t)hash64:(NSString *)input {
    const char* str = [input UTF8String];
    int len = (int)[input length];
    //uint32_t hash;
    void* buff[128/8]; // 128 bit buffer
    MurmurHash3_x86_128(str,len,0,buff);
    // take out lowest 64 bits from buff, ignore upper 64 bit
    uint64_t result = ((uint64_t*)buff)[0];
    return result;
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
