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
    
    double expectedPrediciton = 0.010191867;
    XCTAssert(isEqualRough(prediction, expectedPrediciton));
}

- (void)testBatch {
    
}

@end