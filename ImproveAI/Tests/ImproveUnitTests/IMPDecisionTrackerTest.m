//
//  IMPDecisionTrackerTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 10/29/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPDecisionTracker.h"
#import "IMPDecisionModel.h"
#import "IMPDecision.h"
#import "IMPDecisionContext.h"

NSString * const kTrackerURL = @"https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track";

NSString * const kTrackApiKey = @"api-key";

NSString * const kRemoteModelURL = @"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/songs-2.0.mlmodel.gz";

@interface IMPDecisionModel ()

@property (strong, atomic) IMPDecisionTracker *tracker;

@end

@interface IMPDecisionTracker ()

- (id)sampleVariantOf:(NSArray *)rankedVariants runnersUpCount:(NSUInteger)runnersUpCount;

- (BOOL)shouldTrackRunnersUp:(NSUInteger) variantsCount;

- (NSArray *)topRunnersUp:(NSArray *)ranked;

- (void)setBestVariant:(id)bestVariant dict:(NSMutableDictionary *)body;

- (void)setCount:(NSArray *)variants dict:(NSMutableDictionary *)body;

- (nullable NSString *)createAndPersistDecisionIdForModel:(NSString *)modelName;

@end

@interface IMPTrackerTest : XCTestCase

@end

@implementation IMPTrackerTest

- (IMPDecisionTracker *)tracker {
    NSURL *url = [NSURL URLWithString:kTrackerURL];
    return [[IMPDecisionTracker alloc] initWithTrackURL:url trackApiKey:nil];
}

- (void)testInit_mutable_trackApiKey {
    NSMutableString *trackApiKey = [[NSMutableString alloc] initWithString:@"hello"];
    NSURL *url = [NSURL URLWithString:kTrackerURL];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"hello" trackURL:url trackApiKey:trackApiKey];
    XCTAssertNotNil(decisionModel.tracker.trackApiKey);
    XCTAssertNotEqual(trackApiKey, decisionModel.tracker.trackApiKey);
    XCTAssertEqualObjects(@"hello", decisionModel.tracker.trackApiKey);
    
    // test setter
    decisionModel.tracker.trackApiKey = trackApiKey;
    [trackApiKey setString:@"world"];
    XCTAssertEqualObjects(@"hello", decisionModel.tracker.trackApiKey);
}

// 1 best variant, 1 runner-up, 1 sample
- (void)testSampleVariant_Null_Sample {
    NSArray *variants = @[@"foo", @"bar", [NSNull null]];
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 1;
    
    NSArray *runnersUp = [tracker topRunnersUp:variants];
    
    id sample = [tracker sampleVariantOf:variants runnersUpCount:[runnersUp count]];
    XCTAssertNotNil(sample);
    XCTAssertEqualObjects(sample, [NSNull null]);
}

// If there are no runners up, then sample is a random sample from
// variants with just best excluded.
- (void)testSampleVariant_0_RunnersUp {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 0;

    int loop = 1000000;

    NSMutableDictionary *sampleCountDict = [[NSMutableDictionary alloc] init];
    NSArray *variants = @[@1, @2, @3, @4, @5];
    NSUInteger runnersUpCount = [[tracker topRunnersUp:variants] count];

    for (int i = 0; i < loop; ++i) {
        id sample = [tracker sampleVariantOf:variants runnersUpCount:runnersUpCount];
        sampleCountDict[sample] = @([sampleCountDict[sample] intValue] + 1);
    }

    XCTAssertTrue(ABS(loop/4 - [sampleCountDict[@2] intValue]) < 1000);
    XCTAssertTrue(ABS(loop/4 - [sampleCountDict[@3] intValue]) < 1000);
    XCTAssertTrue(ABS(loop/4 - [sampleCountDict[@4] intValue]) < 1000);
    XCTAssertTrue(ABS(loop/4 - [sampleCountDict[@5] intValue]) < 1000);
    NSLog(@"sampleCount: %d, %d, %d, %d",
          [sampleCountDict[@2] intValue],
          [sampleCountDict[@3] intValue],
          [sampleCountDict[@4] intValue],
          [sampleCountDict[@5] intValue]);
}

// If there are runners up, then sample is a random sample from
// variants with best and runners up excluded.
- (void)testSampleVariant_2_RunnersUp {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 2;

    int loop = 1000000;

    NSMutableDictionary *sampleCountDict = [[NSMutableDictionary alloc] init];
    NSArray *variants = @[@1, @2, @3, @4, @5];
    NSUInteger runnersUpCount = [[tracker topRunnersUp:variants] count];

    for (int i = 0; i < loop; ++i) {
        id sample = [tracker sampleVariantOf:variants runnersUpCount:runnersUpCount];
        sampleCountDict[sample] = @([sampleCountDict[sample] intValue] + 1);
    }

    XCTAssertTrue(ABS(loop/2 - [sampleCountDict[@4] intValue]) < 1000);
    XCTAssertTrue(ABS(loop/2 - [sampleCountDict[@5] intValue]) < 1000);
    NSLog(@"sampleCount: %d, %d",
          [sampleCountDict[@4] intValue],
          [sampleCountDict[@5] intValue]);
}


// If there is only one variant, which is the best, then there is no sample.
- (void)testSampleVariant_1_variant {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;

    NSArray *variants = @[@1];
    NSUInteger runnersUpCount = [[tracker topRunnersUp:variants] count];

    id sampleVariant = [tracker sampleVariantOf:variants runnersUpCount:runnersUpCount];
    XCTAssertNil(sampleVariant);
}

// If there are no remaining variants after best and runners up, then there is no sample.
- (void)testSampleVariant_0_remaining_variants {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;

    NSArray *variants = @[@1, @2, @3, @4, @5];
    NSUInteger runnersUpCount = [[tracker topRunnersUp:variants] count];

    id sampleVariant = [tracker sampleVariantOf:variants runnersUpCount:runnersUpCount];
    XCTAssertNil(sampleVariant);
}

- (void)testShouldTrackRunnersUp_1_variantsCount {
    int loop = 1000000;
    int variantCount = 1;
    int shouldTrackCount = 0;
    
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    for (int i = 0; i < loop; ++i) {
        if([tracker shouldTrackRunnersUp:variantCount]) {
            shouldTrackCount++;
        }
    }
    XCTAssertEqual(shouldTrackCount, 0);
    NSLog(@"shouldTrackCount=%d", shouldTrackCount);
}

- (void)testShouldTrackRunnersUp_2_variantsCount {
    int loop = 1000000;
    int variantCount = 2;
    int shouldTrackCount = 0;
    
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    for (int i = 0; i < loop; ++i) {
        if([tracker shouldTrackRunnersUp:variantCount]) {
            shouldTrackCount++;
        }
    }
    XCTAssertEqual(shouldTrackCount, loop);
    NSLog(@"shouldTrackCount=%d", shouldTrackCount);
}

- (void)testShouldTrackRunnersUp_10_variantsCount {
    int loop = 1000000;
    int variantCount = 10;
    int shouldTrackCount = 0;
    
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    for (int i = 0; i < loop; ++i) {
        if([tracker shouldTrackRunnersUp:variantCount]) {
            shouldTrackCount++;
        }
    }
    XCTAssertEqualWithAccuracy(shouldTrackCount / (double)loop,
                               1.0 / MIN(variantCount-1, tracker.maxRunnersUp),
                               0.001);
    NSLog(@"variantCount=%d, shouldTrackCount probability = %lf", variantCount,
          shouldTrackCount / (double)loop);
}

- (void)testShouldTrackRunnersUp_100_variantsCount {
    int loop = 1000000;
    int variantCount = 100;
    int shouldTrackCount = 0;
    
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    for (int i = 0; i < loop; ++i) {
        if([tracker shouldTrackRunnersUp:variantCount]) {
            shouldTrackCount++;
        }
    }
    XCTAssertEqualWithAccuracy(shouldTrackCount / (double)loop,
                               1.0 / MIN(variantCount-1, tracker.maxRunnersUp),
                               0.001);
    NSLog(@"variantCount=%d, shouldTrackCount probability = %lf", variantCount,
          shouldTrackCount / (double)loop);
}


- (void)testShouldTrackRunnersUp_0_maxRunnersUp {
    int loop = 1000000;
    int variantCount;
    int shouldTrackCount;
    
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 0;
    
    variantCount = 10;
    shouldTrackCount = 0;
    for (int i = 0; i < loop; ++i) {
        if([tracker shouldTrackRunnersUp:variantCount]) {
            shouldTrackCount++;
        }
    }
    XCTAssertEqual(shouldTrackCount, 0);
    NSLog(@"shouldTrackCount=%d", shouldTrackCount);
}

// 1 best variant, 2 runners-up
- (void)testTopRunnersUp_Null_Runnersup {
    NSArray *variants = @[@"foo", [NSNull null], @"bar"];
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    NSArray *runnersUp = [tracker topRunnersUp:variants];
    
    XCTAssertEqual([runnersUp count], 2);
    XCTAssertEqualObjects([runnersUp objectAtIndex:0], [NSNull null]);
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:runnersUp options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(@"[null,\"bar\"]", jsonString);
    NSLog(@"runners up jsonString = %@", jsonString);
    NSLog(@"runners up: %@", runnersUp);
}

- (void)testTopRunnersUp_1_variant {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    NSArray *variants = @[@1];
    NSArray *result = [tracker topRunnersUp:variants];
    XCTAssertEqual(result.count, 0);
}

- (void)testTopRunnersUp_2_variant {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    NSArray *variants = @[@1, @2];
    NSArray *result = [tracker topRunnersUp:variants];
    XCTAssertEqual(result.count, 1);
}

- (void)testTopRunnersUp_10_variants {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    NSMutableArray *variants_10 = [[NSMutableArray alloc] init];
    for(int i = 0; i < 10; ++i) {
        [variants_10 addObject:@(i)];
    }
    NSArray *result = [tracker topRunnersUp:variants_10];
    XCTAssertEqual(result.count, 9);
    for(int i = 0; i < 9; ++i) {
        XCTAssertEqual([result[i] intValue], i+1);
    }
}

- (void)testTopRunnersUp_100_variants {
    IMPDecisionTracker *tracker = [self tracker];
    tracker.maxRunnersUp = 50;
    
    NSMutableArray *variants_100 = [[NSMutableArray alloc] init];
    for(int i = 0; i < 100; ++i) {
        [variants_100 addObject:@(i)];
    }
    NSArray *result = [tracker topRunnersUp:variants_100];
    XCTAssertEqual(result.count, 50);
    for(int i = 0; i < 50; ++i) {
        XCTAssertEqual([result[i] intValue], i+1);
    }
}

- (void)testSetBestVariantNonNil {
    IMPDecisionTracker *tracker = [self tracker];
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [tracker setBestVariant:@"hello" dict:body];
    
    XCTAssertEqualObjects(body[@"variant"], @"hello");
}

- (void)testSetCount_10_variants {
    IMPDecisionTracker *tracker = [self tracker];
    
    NSMutableArray *variants = [[NSMutableArray alloc] init];
    for(int i = 0; i < 10; ++i) {
        [variants addObject:@(i)];
    }
    
    NSMutableDictionary *body = [[NSMutableDictionary alloc] init];
    [tracker setCount:variants dict:body];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSLog(@"jsonString: %@", jsonString);
    
    XCTAssertEqualObjects(body[@"count"], @10);
}

- (void)testTrackerRequest {
    NSURL *trackerUrl = [NSURL URLWithString:kTrackerURL];
    NSArray *variants = @[@"Hello World", @"Howdy World", @"Hi World"];
    NSDictionary *context = @{@"language": @"cowboy"};

    NSError *err;
    NSURL *modelUrl = [NSURL URLWithString:kRemoteModelURL];
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"greetings"];
    [decisionModel load:modelUrl error:&err];
    decisionModel.trackURL = trackerUrl;

    NSString *greeting = [[[decisionModel given:context] chooseFrom:variants] get];
    NSLog(@"greeting=%@", greeting);

    [NSThread sleepForTimeInterval:6];
}

- (void)testTrackingNonJsonEncodable {
    NSURL *trackerUrl = [NSURL URLWithString:kTrackerURL];
    NSArray *variants = @[trackerUrl];
    NSDictionary *context = @{@"language": @"cowboy"};
    
    IMPDecisionModel *decisionModel = [[IMPDecisionModel alloc] initWithModelName:@"theme"];
    decisionModel.trackURL = trackerUrl;
    [[[decisionModel given:context] chooseFrom:variants] get];
}

- (void)testAddReward_NaN {
    NSString *modelName = @"test_AddReward_NaN";
    IMPDecisionTracker *tracker = [self tracker];
    [tracker createAndPersistDecisionIdForModel:modelName];
    @try {
        [tracker addReward:NAN forModel:modelName];
    } @catch(id exception) {
        NSLog(@"addReward exception: %@", exception);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should never reach here.");
}

- (void)testAddReward_Negative_Infinity {
    NSString *modelName = @"test_AddReward_Infinity";
    IMPDecisionTracker *tracker = [self tracker];
    [tracker createAndPersistDecisionIdForModel:modelName];
    @try {
        [tracker addReward:-INFINITY forModel:modelName];
    } @catch(id exception) {
        NSLog(@"addReward exception: %@", exception);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should never reach here.");
}

- (void)testAddReward_Positive_Infinity {
    NSString *modelName = @"test_AddReward_Infinity";
    IMPDecisionTracker *tracker = [self tracker];
    [tracker createAndPersistDecisionIdForModel:modelName];
    @try {
        [tracker addReward:INFINITY forModel:modelName];
    } @catch(id exception) {
        NSLog(@"addReward exception: %@", exception);
        return ;
    }
    XCTFail(@"An exception should have been thrown, we should never reach here.");
}

- (void)testAddReward_Valid {
    IMPDecisionTracker *tracker = [self tracker];
    [tracker addReward:1.0 forModel:@"hello"];
    [tracker addReward:0.1 forModel:@"hello"];
    [tracker addReward:-1.0 forModel:@"hello"];
}

- (NSURL *)modelUrl {
    return [NSURL URLWithString:kRemoteModelURL];
}

@end
