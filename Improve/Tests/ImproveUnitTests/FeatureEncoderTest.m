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
#import "TestUtils.h"

// double precision: 15 decimal digits after dot
#define accuracy 0.000000000000001

@interface FeatureEncoderTest : XCTestCase

@end

@implementation FeatureEncoderTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        if([check[key] isKindOfClass:[NSString class]] && [check[key] isEqualToString:@"inf"]){
            XCTAssertEqualWithAccuracy([encoded[key] doubleValue], INFINITY, accuracy);
        } else {
//            XCTAssertEqualWithAccuracy([encoded[key] doubleValue], [check[key] doubleValue], accuracy);
            XCTAssertEqual([encoded[key] doubleValue], [check[key] doubleValue]);
        }
    }
}

// ll | grep -v total | grep -v feature_encoder_test_suite.txt | awk -F " " '{print $9}' > feature_encoder_test_suite.txt
- (void)testFeatureEncoding{
    NSURL *testsuiteURL = [[TestUtils bundle] URLForResource:@"feature_encoder_test_suite.txt" withExtension:nil];
    NSString *allTestsStr = [[NSString alloc] initWithContentsOfURL:testsuiteURL encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue(allTestsStr.length>1);
    // remove trailing newline
    if([allTestsStr hasSuffix:@"\n"]){
        allTestsStr = [allTestsStr substringToIndex:allTestsStr.length-1];
    }
    
    NSArray *allTestFileNames = [allTestsStr componentsSeparatedByString:@"\n"];
    XCTAssertTrue(allTestFileNames.count > 1);
    
    for (NSString *filename in allTestFileNames) {
        NSURL *url = [[TestUtils bundle] URLForResource:filename withExtension:nil];
        NSData *data = [NSData dataWithContentsOfURL:url];
        XCTAssertNotNil(data);
        
        NSError *err = nil;
        NSDictionary *root = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
        if(err != nil){
            IMPLog("%@, invalid json: %@", filename, err);
        }
        XCTAssertNil(err);
        XCTAssertNotNil(root);
        
        [self verify:filename withData:root];
    }
}

- (void)verify:(NSString *)filename withData:(NSDictionary *)root{
    IMPFeatureEncoder *featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:1 andFeatureNames:[NSSet new]];
    featureEncoder.testMode = YES;
    featureEncoder.noise = [[root objectForKey:@"noise"] doubleValue];
    
    id variants = [[root objectForKey:@"test_case"] objectForKey:@"variant"];
    id context = [[root objectForKey:@"test_case"] objectForKey:@"context"];
    
    NSArray<NSDictionary *> *features = [featureEncoder encodeVariants:@[variants] given:context];
    XCTAssertTrue(features.count == 1);
    NSLog(@"%@, features: %@", filename, features);
    
    NSDictionary *expected = [root objectForKey:@"test_output"];
    NSDictionary *test = features[0];
    
    [NSNumber numberWithDouble:NAN];
    
    [self assertDictionary:test equalTo:expected];
}

- (void)testNaN{
    IMPFeatureEncoder *featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:1 andFeatureNames:[NSSet new]];
    featureEncoder.testMode = YES;
    featureEncoder.noise = 0.8928601514360016;
    
    id variants = [NSNumber numberWithDouble:NAN];
    
    NSArray<NSDictionary *> *features = [featureEncoder encodeVariants:@[variants] given:nil];
    XCTAssertTrue(features.count == 1);
    
    NSDictionary *expected = @{};
    NSDictionary *test = features[0];
    
    [self assertDictionary:test equalTo:expected];
}

- (void)testNullCharacter{
    IMPFeatureEncoder *featureEncoder = [[IMPFeatureEncoder alloc] initWithModelSeed:1 andFeatureNames:[NSSet new]];
    featureEncoder.testMode = YES;
    featureEncoder.noise = 0.8928601514360016;
    
    id variants = @{@"$value":@{@"\0\0\0\0\0\0\0\0":@"foo", @"\0\0\0\0\0\0\0\1":@"bar"}};
    
    NSArray<NSDictionary *> *features = [featureEncoder encodeVariants:@[variants] given:nil];
    XCTAssertTrue(features.count == 1);
    
    NSDictionary *expected = @{@"8946516b":@(11509.078405916971),
                               @"55ae894":@(26103.177819987483),
                               @"4bfbc00e":@(-19661.13392357309),
                               @"463cc537":@(-13292.090538057455)};
    NSDictionary *test = features[0];
    
    [self assertDictionary:test equalTo:expected];
}

@end
