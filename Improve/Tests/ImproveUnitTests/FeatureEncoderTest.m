//
//  FeatureEncoderTest.m
//  FeatureEncoderTest
//
//  Created by PanHongxi on 3/13/21.
//

#import <XCTest/XCTest.h>
#include <sys/time.h>
#import "IMPFeatureEncoder.h"
#import "IMPJSONUtils.h"

// double precision: 15 decimal digits after dot
#define accuracy 0.000000000000001

@interface FeatureEncoderTest : XCTestCase

@property (strong, nonatomic) IMPFeatureEncoder *encoder;

@end

@implementation FeatureEncoderTest

- (IMPFeatureEncoder *)encoder {
    if(!_encoder) {
        // TODO load feature names from model
        NSSet *modelFeatureNames = [[NSSet alloc] init];
        _encoder = [[IMPFeatureEncoder alloc] initWithModelSeed:3 andFeatureNames:modelFeatureNames];
    }
    return _encoder;
}

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testEncodeContext_noise_0_0{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"1c880fa3\": -24314.0, \"8a1f6c24\": 31780.0}, {\"1c880fa3\": 0.0}, {\"1c880fa3\": 1.0}, {\"1c880fa3\": -1.0}, {\"1c880fa3\": 2.2}, {\"1c880fa3\": -2.2}, {\"1c880fa3\": 1.0}, {\"1c880fa3\": 0.0}, {}, {}, {}, {\"208ed69e\": 20261.0, \"d07ea4a7\": 5077.0, \"90a2432b\": 0.0, \"ad0f4781\": 1.0, \"15860e3\": -1.0, \"46a829c1\": 2.2, \"38109369\": -2.2, \"a35fe471\": 1.0, \"cd3069be\": 0.0}, {\"8a1f6c24\": 20294.0, \"880d71a6\": 7480.0, \"654a09e2\": 0.0, \"dcf93e66\": 1.0, \"b2979960\": -1.0, \"d83082cc\": 2.2, \"6f34c8c1\": -2.2, \"236c4ee9\": 1.0, \"63889e17\": 0.0}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 0.0;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSDictionary *encoded = [self.encoder encodeContext:tests[i] withNoise:noise];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testEncodeContext_noise_0_5{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"1c880fa3\": -24314.092746734605, \"8a1f6c24\": 31780.121234893813}, {\"1c880fa3\": 3.814711817540228e-06}, {\"1c880fa3\": 1.0000076294090832}, {\"1c880fa3\": -0.9999999999854481}, {\"1c880fa3\": 2.200012207045802}, {\"1c880fa3\": -2.200004577622167}, {\"1c880fa3\": 1.0000076294090832}, {\"1c880fa3\": 3.814711817540228e-06}, {}, {}, {}, {\"208ed69e\": 20261.07729339601, \"d07ea4a7\": 5077.019371032729, \"90a2432b\": 3.814711817540228e-06, \"ad0f4781\": 1.0000076294090832, \"15860e3\": -0.9999999999854481, \"46a829c1\": 2.200012207045802, \"38109369\": -2.200004577622167, \"a35fe471\": 1.0000076294090832, \"cd3069be\": 3.814711817540228e-06}, {\"8a1f6c24\": 20294.07741928102, \"880d71a6\": 7480.028537750259, \"654a09e2\": 3.814711817540228e-06, \"dcf93e66\": 1.0000076294090832, \"b2979960\": -0.9999999999854481, \"d83082cc\": 2.200012207045802, \"6f34c8c1\": -2.200004577622167, \"236c4ee9\": 1.0000076294090832, \"63889e17\": 3.814711817540228e-06}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 0.5;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSDictionary *encoded = [self.encoder encodeContext:tests[i] withNoise:noise];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testEncodeContext_noise_1_0{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"1c880fa3\": -24314.18549346918, \"8a1f6c24\": 31780.242469787656}, {\"1c880fa3\": 7.629452738910913e-06}, {\"1c880fa3\": 1.0000152588472702}, {\"1c880fa3\": -0.9999999999417923}, {\"1c880fa3\": 2.200024414120708}, {\"1c880fa3\": -2.20000915521523}, {\"1c880fa3\": 1.0000152588472702}, {\"1c880fa3\": 7.629452738910913e-06}, {}, {}, {}, {\"208ed69e\": 20261.15458679205, \"d07ea4a7\": 5077.038742065488, \"90a2432b\": 7.629452738910913e-06, \"ad0f4781\": 1.0000152588472702, \"15860e3\": -0.9999999999417923, \"46a829c1\": 2.200024414120708, \"38109369\": -2.20000915521523, \"a35fe471\": 1.0000152588472702, \"cd3069be\": 7.629452738910913e-06}, {\"8a1f6c24\": 20294.15483856207, \"880d71a6\": 7480.0570755005465, \"654a09e2\": 7.629452738910913e-06, \"dcf93e66\": 1.0000152588472702, \"b2979960\": -0.9999999999417923, \"d83082cc\": 2.200024414120708, \"6f34c8c1\": -2.20000915521523, \"236c4ee9\": 1.0000152588472702, \"63889e17\": 7.629452738910913e-06}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 1.0;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSDictionary *encoded = [self.encoder encodeContext:tests[i] withNoise:noise];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testEncodeVariant_noise_0_0{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"8064524e\": -3917.0, \"73219c48\": -20645.0}, {\"8064524e\": 0.0}, {\"8064524e\": 1.0}, {\"8064524e\": -1.0}, {\"8064524e\": 2.2}, {\"8064524e\": -2.2}, {\"8064524e\": 1.0}, {\"8064524e\": 0.0}, {}, {}, {}, {\"d5bb39fe\": -4074.0, \"3c762801\": 25210.0, \"872af148\": 0.0, \"83f7559c\": 1.0, \"5daccb55\": -1.0, \"ec356369\": 2.2, \"bef22eed\": -2.2, \"ed3f4fa2\": 1.0, \"f89dc00e\": 0.0}, {\"cccb13f\": -4208.0, \"1b4eff6e\": -15857.0, \"68d9e9ce\": 0.0, \"f9480b00\": 1.0, \"f5a8ffad\": -1.0, \"af400a40\": 2.2, \"2ff3edd9\": -2.2, \"24f40649\": 1.0, \"90be6c6\": 0.0}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 0.0;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSMutableDictionary *encoded = [[NSMutableDictionary alloc] init];
        [self.encoder encodeVariant:tests[i] withNoise:noise forFeatures:encoded];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testEncodeVariant_noise_0_5{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"8064524e\": -3917.0149383544776, \"73219c48\": -20645.078750610337}, {\"8064524e\": 3.814711817540228e-06}, {\"8064524e\": 1.0000076294090832}, {\"8064524e\": -0.9999999999854481}, {\"8064524e\": 2.200012207045802}, {\"8064524e\": -2.200004577622167}, {\"8064524e\": 1.0000076294090832}, {\"8064524e\": 3.814711817540228e-06}, {}, {}, {}, {\"d5bb39fe\": -4074.0155372619483, \"3c762801\": 25210.09617233278, \"872af148\": 3.814711817540228e-06, \"83f7559c\": 1.0000076294090832, \"5daccb55\": -0.9999999999854481, \"ec356369\": 2.200012207045802, \"bef22eed\": -2.200004577622167, \"ed3f4fa2\": 1.0000076294090832, \"f89dc00e\": 3.814711817540228e-06}, {\"cccb13f\": -4208.016048431382, \"1b4eff6e\": -15857.06048583983, \"68d9e9ce\": 3.814711817540228e-06, \"f9480b00\": 1.0000076294090832, \"f5a8ffad\": -0.9999999999854481, \"af400a40\": 2.200012207045802, \"2ff3edd9\": -2.200004577622167, \"24f40649\": 1.0000076294090832, \"90be6c6\": 3.814711817540228e-06}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 0.5;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSMutableDictionary *encoded = [[NSMutableDictionary alloc] init];
        [self.encoder encodeVariant:tests[i] withNoise:noise forFeatures:encoded];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testEncodeVariant_noise_1_0{
    NSString *testsString = @"[\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}, [\"string\", 0, 1, -1, 2.2, -2.2, true, false, null, [], {}], {\"string\": \"string\", \"zero\": 0, \"nested dict\": {\"one\": 1, \"nested dict\": {\"minus one\": -1}}, \"nested array\": [2.2, [-2.2, {\"true\": true, \"false\": false}]], \"nulls\": [[], {}]}]";
    NSArray *tests = [IMPJSONUtils objectFromString:testsString];
    
    NSString *checksString = @"[{\"8064524e\": -3917.029876708926, \"73219c48\": -20645.157501220645}, {\"8064524e\": 7.629452738910913e-06}, {\"8064524e\": 1.0000152588472702}, {\"8064524e\": -0.9999999999417923}, {\"8064524e\": 2.200024414120708}, {\"8064524e\": -2.20000915521523}, {\"8064524e\": 1.0000152588472702}, {\"8064524e\": 7.629452738910913e-06}, {}, {}, {}, {\"d5bb39fe\": -4074.0310745238676, \"3c762801\": 25210.192344665586, \"872af148\": 7.629452738910913e-06, \"83f7559c\": 1.0000152588472702, \"5daccb55\": -0.9999999999417923, \"ec356369\": 2.200024414120708, \"bef22eed\": -2.20000915521523, \"ed3f4fa2\": 1.0000152588472702, \"f89dc00e\": 7.629452738910913e-06}, {\"cccb13f\": -4208.032096862735, \"1b4eff6e\": -15857.12097167963, \"68d9e9ce\": 7.629452738910913e-06, \"f9480b00\": 1.0000152588472702, \"f5a8ffad\": -0.9999999999417923, \"af400a40\": 2.200024414120708, \"2ff3edd9\": -2.20000915521523, \"24f40649\": 1.0000152588472702, \"90be6c6\": 7.629452738910913e-06}]";
    NSArray *checks = [IMPJSONUtils objectFromString:checksString];
    
    double noise = 1.0;
    for(NSUInteger i = 0; i < tests.count; i++){
        NSMutableDictionary *encoded = [[NSMutableDictionary alloc] init];
        [self.encoder encodeVariant:tests[i] withNoise:noise forFeatures:encoded];
        NSDictionary *check = checks[i];
        NSLog(@"Index: %ld\nActual:\n%@\nExpected:\n%@", i, encoded, check);
        [self assertDictionary:encoded equalTo:check];
    }
}

- (void)testInt2Hex{
    double d1 = 0.0;
    double d2 = 0.0;
    int loop = 1000;
    for(uint64_t i = 0; i < loop; i++){
        struct timeval t1, t2, t3, t4;
        gettimeofday(&t1, NULL);
        for(uint64_t j = 0; j < 20000; ++j){
            uint64_t value = (j<<32)+0xffffffff;
            [self customInt2Hex:value];
        }
        gettimeofday(&t2, NULL);
        d1 += (t2.tv_sec-t1.tv_sec) * 1000 + (t2.tv_usec - t1.tv_usec)/1000.0;
        

        gettimeofday(&t3, NULL);
        for(uint64_t j = 0; j < 20000; ++j){
            uint64_t value = (j<<32)+0xffffffff;
            [self sprintfInt2Hex:value];
        }
        gettimeofday(&t4, NULL);
        d2 += (t4.tv_sec-t3.tv_sec) * 1000 + (t4.tv_usec - t3.tv_usec)/1000.0;
    }
    
    NSLog(@"int2hex, run 20000 times, average cost: %lfms", d1/loop);
    NSLog(@"sprintf, run 20000 times, average cost: %lfms", d2/loop);
}

- (NSString *)sprintfInt2Hex:(uint64_t)hash{
    char buffer[12];
    sprintf(buffer, "%x", (uint32_t)(hash>>32));
    return @(buffer);
}

- (NSString *)customInt2Hex:(uint64_t)hash{
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
    
    // skip leading zero
    for(int i = 0; i < 8; ++i){
        if(buffer[i] != '0'){
            return @(buffer+i);
        }
    }
    return @"0";
}

- (void)assertDictionary:(NSDictionary *)encoded equalTo:(NSDictionary *)check{
    XCTAssert(encoded.count == check.count);
    for (NSString *key in check) {
        XCTAssertEqualWithAccuracy([encoded[key] doubleValue], [check[key] doubleValue], accuracy);
    }
}

@end
