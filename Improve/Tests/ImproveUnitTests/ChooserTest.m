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


const NSUInteger featuresCount = 10000;

@interface ChooserTest : XCTestCase {
    NSBundle *bundle;
    IMPChooser *chooser;
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

@end
