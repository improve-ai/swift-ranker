//
//  ChooserTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/26/20.
//

#import <XCTest/XCTest.h>
#import "TestUtils.h"
#import "IMPChooser.h"
#import "IMPModelMetadata.h"
#import "IMPFeatureHasher.h"
#import "MLMultiArray+NSArray.h"
#import "NSArray+Padding.h"
#import "IMPScoredObject.h"
#import "IMPJSONUtils.h"
#import "TestUtils.h"

// File names without extensions
NSString *const kModelFileName = @"TestModel";
NSString *const kMetadataFileName = @"TestModel";


@interface IMPChooser ()
- (NSArray *)batchPrediction:(NSArray<NSDictionary<NSNumber*,id>*> *)batchFeatures;

- (id)bestSampleFrom:(NSArray *)variants forScores:(NSArray *)scores;
@end

@interface ChooserTest : XCTestCase {
    IMPChooser *chooser;
}
@end

@implementation ChooserTest

- (void)setUp {
    chooser = [[IMPChooser alloc] initWithModel:[self loadModel]
                                       metadata:[self loadMetadata]];
    XCTAssertNotNil(chooser);
}

- (MLModel *)loadModel {
    NSURL *modelURL = [[TestUtils bundle] URLForResource:kModelFileName
                                           withExtension:@"mlmodelc"];
    XCTAssertNotNil(modelURL);
    NSError *err;
    MLModel *model = [MLModel modelWithContentsOfURL:modelURL
                                               error:&err];
    if (!model) {
        XCTFail("Failed to parse model: %@", err);
    }
    return model;
}

- (IMPModelMetadata *)loadMetadata {
    NSError *err;

    NSURL *metadataURL = [[TestUtils bundle] URLForResource:kMetadataFileName
                                              withExtension:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:metadataURL
                                             options:0
                                               error:&err];
    if (!jsonData) {
        XCTFail(@"Failed to load metadata: %@", err);
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                             options:0
                                                               error:&err];
    if (!jsonDict) {
        XCTFail(@"Failed to parse metadata JSON: %@", err);
    }
    IMPModelMetadata *metadata = [[IMPModelMetadata alloc] initWithDict:jsonDict];
    return metadata;
}

// TODO: Isolated test for batch prediction

- (void)testBasicChoosing {
    XCTAssertNotNil(chooser);
    NSArray *variants = [TestUtils defaultTrials];
    NSDictionary *context = @{};
    NSDictionary *chosen = [chooser choose:variants context:context];
    XCTAssertNotNil(chosen);
    NSLog(@"Chosen: %@", chosen);
}

- (void)testSort {
    NSArray *variants = [TestUtils defaultTrials];
    NSDictionary *context = @{};
    NSArray *rankedVariants = [chooser sort:variants context:context];
    XCTAssertNotNil(rankedVariants);

    NSArray *scores = [TestUtils defaultPredictions];
    NSMutableArray *xgboostScored = [NSMutableArray arrayWithCapacity:variants.count];
    for (NSUInteger i = 0; i < variants.count; i++) {
        double xgbScore = [scores[i] doubleValue];
        [xgboostScored addObject:[IMPScoredObject withScore:xgbScore
                                                     object:variants[i]]];
    }
    [xgboostScored sortUsingDescriptors:@[
        [NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]
    ]];
    NSMutableArray *expectedRankedVariants = [NSMutableArray arrayWithCapacity:xgboostScored.count];
    for (NSUInteger i = 0; i < xgboostScored.count; i++) {
        [expectedRankedVariants addObject:[xgboostScored[i] object]];
    }
    NSLog(@"Ranked: %@", rankedVariants);
    NSLog(@"Expected: %@", expectedRankedVariants);
    XCTAssert([rankedVariants isEqualToArray:expectedRankedVariants]);
}

// TODO: provide variants and context
//- (void)testChoosePerformance {
//    XCTAssertNotNil(chooser);
//
//    XCTMeasureOptions *options = [[self class] defaultMeasureOptions];
//    options.iterationCount = 1000;
//    [self measureWithOptions:options block:^{
//        NSDictionary *chosen = [chooser choose:variants context:context];
//        XCTAssertNotNil(chosen);
//    }];
//}

- (void)testReservoirSampling {
    // Input
    NSArray *testSamples = @[@"a", @"b", @"c", @"d", @"e", @"f", @"g", @"h", @"i", @"j", @"k", @"l"];
    NSArray *testScores = @[@1, @1, @5, @3, @2, @5, @1, @4, @5, @2, @-100, @0];
    const NSInteger iterationsCount = 10000;
    const double tolerance = 0.2;
    assert(testSamples.count == testScores.count);

    // Process input and predict expected results
    NSNumber *bestScore = [testScores sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO]]][0];
    NSMutableArray *bestSamples = [NSMutableArray new];
    for (NSInteger i = 0; i < testScores.count; i++)
    {
        if ([testScores[i] isEqual:bestScore]) {
            [bestSamples addObject:testSamples[i]];
        }
    }
    NSLog(@"Predicted best samples: %@", bestSamples);
    double expectedProportion = 1.0 / (double)(bestSamples.count);

    // Perform randomised sampling
    NSInteger *counts = calloc(testSamples.count, sizeof(NSInteger));
    for (NSInteger iteration = 0; iteration < iterationsCount; iteration++)
    {
        id sample = [chooser bestSampleFrom:testSamples forScores:testScores];
        NSInteger index = [testSamples indexOfObject:sample];
        XCTAssert(index != NSNotFound);
        counts[index] += 1;
    }

    // Analyze
    for (NSInteger i = 0; i < testSamples.count; i++) {
        id sample = testSamples[i];
        NSInteger count = counts[i];
        NSLog(@"%@: %ld", sample, count);
        if ([bestSamples containsObject:sample]) {
            double proportion = (double)count / iterationsCount;
            XCTAssert(isEqualRough(proportion / expectedProportion, 1.0, tolerance));
        } else {
            XCTAssert(count == 0);
        }
    }

    free(counts);
}

@end
