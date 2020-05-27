//
//  ChooserTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/26/20.
//

#import <XCTest/XCTest.h>
#import "IMPChooser.h"
#import "IMPFeatureHasher.h"
#import "MLMultiArray+NSArray.h"
#import "NSArray+Padding.h"
#import "TestUtils.h"
#import "IMPScoredObject.h"
#import "IMPModelBundle.h"
#import "IMPJSONUtils.h"
#import "TestUtils.h"

const NSUInteger featuresCount = 10000;

@interface IMPChooser ()
- (NSArray *)batchPrediction:(NSArray<NSDictionary<NSNumber*,id>*> *)batchFeatures;
- (double)singleRowPrediction:(NSDictionary<NSNumber*,id> *)features;
@end

@interface ChooserTest : XCTestCase {
    IMPChooser *chooser;
}
@end

@implementation ChooserTest

- (instancetype)initWithInvocation:(NSInvocation *)invocation {
    self = [super initWithInvocation:invocation];
    if (self) {
        NSURL *modelURL = [[TestUtils bundle] URLForResource:@"TestModel"
                                               withExtension:@"mlmodelc"];
        XCTAssertNotNil(modelURL);
        NSURL *metadataURL = [[TestUtils bundle] URLForResource:@"TestModel"
                                                  withExtension:@"json"];
        IMPModelBundle *modelBundle = [[IMPModelBundle alloc] initWithModelURL:modelURL
                                                                   metadataURL:metadataURL];
        chooser = [IMPChooser chooserWithModelBundle:modelBundle namespace:@"default" error:nil];
        XCTAssertNotNil(chooser);
    }
    return self;
}

- (void)testSingleRow {
    XCTAssertNotNil(chooser);
    NSLog(@"%ld", __STDC_VERSION__);

    NSURL *jsonURL = [[TestUtils bundle] URLForResource:@"singleEncodedTrial" withExtension:@"json"];
    XCTAssertNotNil(jsonURL);
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
    XCTAssertNotNil(jsonData);
    NSError *error = nil;
    NSDictionary *encodedTrial = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                 options:0
                                                                   error:&error];
    if (!encodedTrial) {
        XCTFail(@"%@", error);
    }

    encodedTrial = [IMPJSONUtils convertKeysToIntegers:encodedTrial];

    double prediction = [chooser singleRowPrediction:encodedTrial];
    NSLog(@"Single row prediction: %g", prediction);
    XCTAssert(prediction != -1.0); // Check for errors
    
    double expectedPrediciton = 0.003574190428480506;
    XCTAssert(isEqualRough(prediction, expectedPrediciton));
}

- (void)testSingleAndBatchConsistency {
    NSArray *trials = [TestUtils defaultTrials];
    NSArray *predictions = [TestUtils defaultPredictions];

    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithMetadata:chooser.metadata];
    NSArray *hashedTrials = [hasher batchEncode:trials];

    NSArray *batchScores = [chooser batchPrediction:hashedTrials];
    NSLog(@"%@", batchScores);
    XCTAssertNotNil(batchScores);

    for (NSUInteger i = 0; i < hashedTrials.count; i++)
    {
        NSDictionary *hashedTrial = hashedTrials[i];
        double singleScore = [chooser singleRowPrediction:hashedTrial];
        double batchScore = [batchScores[i] doubleValue];
        double XGBScore = [predictions[i] doubleValue];
        NSLog(@"batch|single|xgboost: %f, %f, %f", batchScore, singleScore, XGBScore);

        XCTAssert(isEqualRough(XGBScore, singleScore));
        XCTAssert(isEqualRough(XGBScore, batchScore));
    }
}

/*
 Shallow test, only for general output shape. Choosing isn't reproducible because
 of it's random nature.
 */
- (void)testBasicChoosing {
    XCTAssertNotNil(chooser);

    NSDictionary *variants;
    NSDictionary *context;
    [self getRealLifeVariants:&variants context:&context];

    NSDictionary *chosen = [chooser choose:variants context:context];
    XCTAssertNotNil(chosen);
    NSLog(@"%@", chosen);

    // This check insures that all keys are presented in the chosen variant
    NSMutableDictionary *firstVariant = [NSMutableDictionary new];
    for (NSString *propertyName in variants)
    {
        NSArray *propertyValues = variants[propertyName];
        firstVariant[propertyName] = propertyValues.firstObject;
    }
    NSSet *chosenKeys = [NSSet setWithArray:chosen.allKeys];
    NSSet *keys = [NSSet setWithArray:firstVariant.allKeys];
    XCTAssert([chosenKeys isEqualToSet:keys]);
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

- (void)testChoosePerformance {
    XCTAssertNotNil(chooser);

    NSDictionary *variants;
    NSDictionary *context;
    [self getRealLifeVariants:&variants context:&context];

    XCTMeasureOptions *options = [[self class] defaultMeasureOptions];
    options.iterationCount = 1000;
    [self measureWithOptions:options block:^{
        NSDictionary *chosen = [chooser choose:variants context:context];
        XCTAssertNotNil(chosen);
    }];
}

#pragma mark Helpers

- (void)getRealLifeVariants:(NSDictionary **)variants context:(NSDictionary **)context {
    NSURL *jsonURL = [[TestUtils bundle] URLForResource:@"choose"
                                          withExtension:@"json"];
    XCTAssertNotNil(jsonURL);
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
    XCTAssertNotNil(jsonData);
    NSError *error = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData
                                                         options:0
                                                           error:&error];
    if (!json) {
        XCTFail(@"%@", error);
    }

    *variants = json[@"variants"];
    XCTAssertNotNil(*variants);
    XCTAssert((*variants).count > 0);
    *context = json[@"context"];
    XCTAssertNotNil(*context);
}

@end
