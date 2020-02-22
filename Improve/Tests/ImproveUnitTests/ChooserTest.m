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

const NSUInteger featuresCount = 10000;

@interface IMPChooser ()
- (NSArray *)batchPrediction:(IMPMatrix *)matrix;
- (double)singleRowPrediction:(NSArray<NSNumber*> *)features;
@end

@interface ChooserTest : XCTestCase {
    NSBundle *bundle;
    IMPChooser *chooser;
    NSDictionary *_data;
}
@end

@implementation ChooserTest

- (instancetype)initWithInvocation:(NSInvocation *)invocation {
    self = [super initWithInvocation:invocation];
    if (self) {
        bundle = [NSBundle bundleForClass:[self class]];
        NSURL *modelURL = [bundle URLForResource:@"Chooser" withExtension:@"mlmodelc"];
        XCTAssertNotNil(modelURL);
        chooser = [IMPChooser chooserWithModelURL:modelURL error:nil];
        XCTAssertNotNil(chooser);
    }
    return self;
}

/// Contains random "trials" and "predictions" array produced by XGBoost.
- (NSDictionary *)data {
    if (_data) return _data;

    NSURL *jsonURL = [bundle URLForResource:@"trials" withExtension:@"json"];
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
    XCTAssertNotNil(json[@"trials"]);
    XCTAssertNotNil(json[@"predictions"]);

    _data = json;
    return _data;
}

- (void)testSingleRow {
    XCTAssertNotNil(chooser);
    
    NSURL *jsonURL = [bundle URLForResource:@"singleTrial" withExtension:@"json"];
    XCTAssertNotNil(jsonURL);
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
    XCTAssertNotNil(jsonData);
    NSError *error = nil;
    NSDictionary *testTrial = [NSJSONSerialization JSONObjectWithData:jsonData
                                                              options:0
                                                                error:&error];
    if (!testTrial) {
        XCTFail(@"%@", error);
    }
    
    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithNumberOfFeatures:featuresCount];
    NSArray *hashedTrial = [[hasher transform:@[testTrial]] NSArray][0];
    
    double prediction = [chooser singleRowPrediction:hashedTrial];
    NSLog(@"Single row prediction: %g", prediction);
    XCTAssert(prediction != -1.0); // Check for errors
    
    double expectedPrediciton = 3.018615e-05;
    XCTAssert(isEqualRough(prediction, expectedPrediciton));
}

- (void)testSingleAndBatchConsistency {
    NSArray *trials = self.data[@"trials"];
    NSArray *predictions = self.data[@"predictions"];

    IMPFeatureHasher *hasher = [[IMPFeatureHasher alloc] initWithNumberOfFeatures:featuresCount];
    IMPMatrix *hashedTrials = [hasher transform:trials];

    NSArray *batchScores = [chooser batchPrediction:hashedTrials];
    NSLog(@"%@", batchScores);
    XCTAssertNotNil(batchScores);

    NSArray *hashedTrialsArr = [hashedTrials NSArray];
    for (NSUInteger i = 0; i < hashedTrialsArr.count; i++)
    {
        NSArray *hashRow = hashedTrialsArr[i];
        double singleScore = [chooser singleRowPrediction:hashRow];
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

    NSURL *jsonURL = [bundle URLForResource:@"choose" withExtension:@"json"];
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

    NSDictionary *variants = json[@"variants"];
    XCTAssertNotNil(variants);
    XCTAssert(variants.count > 0);
    NSDictionary *context = json[@"context"];
    XCTAssertNotNil(context);

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

- (void)testRank {
    NSArray *variants = self.data[@"trials"];
    NSDictionary *context = @{
        @"language": @"English",
        @"country": @"United States",
        @"day": @100,
        @"os_version": @"13.2"
    };
    NSArray *rankedVariants = [chooser rank:variants context:context];
    XCTAssertNotNil(rankedVariants);

    NSArray *scores = self.data[@"predictions"];
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
    XCTAssert([rankedVariants isEqualToArray:expectedRankedVariants]);
}

@end
