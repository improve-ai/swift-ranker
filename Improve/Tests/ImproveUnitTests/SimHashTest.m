//
//  SimHashTest.m
//  ImproveUnitTests
//
//  Created by Vladimir on 3/25/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "IMPSimHash.h"

@interface SimHashTest : XCTestCase

@end

@implementation SimHashTest

- (void)testNonZeroOutput {
    // Test one string at time
    NSArray *strings = @[
        @"aa",
        @"3x lessons with examples",
        @"simhash differs from most hashes in that its goal is to have two similar documents produce similar hashes, where most hashes have the goal of producing very different hashes even in the face of small changes to the input. The input to simhash is a list of hashes representative of a document. The output is an unsigned 64-bit integer. The input list of hashes can be produced in several ways, but one common mechanism is to: tokenize the document, consider overlapping shingles of these tokens, hash these overlapping shingles, input these hashes into simhash.compute. This has the effect of considering phrases in a document, rather than just a bag of the words in it. Once we've produced a simhash, we would like to compare it to other documents. For two documents to be considered near-duplicates, they must have few bits that differ.",
        @"Benchmark probability after soldering through a project."
    ];
    for (NSString *str in strings)
    {
        IMPSimHashOutput output = [IMPSimHash transform:[NSSet setWithObject:str]];
        // We expect to have at least one non-zero counter.
        BOOL hasNonZero = NO;
        for (int i = 0; i < IMP_SIMHASH_SIZE; i++)
        {
            if (output.counters[i] != 0) hasNonZero = true;
        }
        XCTAssert(hasNonZero);
    }

}

@end
