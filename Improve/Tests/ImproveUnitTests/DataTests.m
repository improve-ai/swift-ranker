//
//  DataTests.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/5/20.
//

#import <XCTest/XCTest.h>
#import "IMPMatrix.h"
#import "TestUtils.h"

// Tests for custom data structures.
@interface DataTests : XCTestCase

@end

@implementation DataTests

- (void)testMatrix
{
    NSUInteger rows = 50;
    NSUInteger cols = 1000;
    IMPMatrix *matrix = [[IMPMatrix alloc] initWithRows:rows columns:cols];
    // Test indexed access
    for (NSUInteger r = 0; r < rows; r++) {
        for (NSUInteger c = 0; c < cols; c++) {
            double randomValue = arc4random_uniform(100);
            matrix.buffer[c + r * cols] = randomValue;
            XCTAssert(isEqualRough(randomValue, [matrix valueAtRow:r column:c]));

            randomValue = arc4random_uniform(100);
            [matrix setValue:randomValue atRow:r column:c];
            XCTAssert(isEqualRough(randomValue, matrix.buffer[c + r * cols]));
        }
    }
}

@end
