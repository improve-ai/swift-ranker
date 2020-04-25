//
//  TestUtils.m
//  ImproveUnitTests
//
//  Created by Vladimir on 4/24/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "TestUtils.h"


@implementation TestUtils

+ (NSBundle *)bundle {
    return [NSBundle bundleForClass:self];
}

+ (NSDictionary *)defaultTrialsAndPredictions
{
    static NSDictionary *trialsAndPredictions;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *jsonURL = [[self bundle] URLForResource:@"trials" withExtension:@"json"];
        assert(jsonURL != nil);
        NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
        assert(jsonData != nil);
        NSError *error = nil;
        trialsAndPredictions = [NSJSONSerialization JSONObjectWithData:jsonData
                                                               options:0
                                                                 error:&error];
        assert(trialsAndPredictions[@"trials"] != nil);
        assert(trialsAndPredictions[@"predictions"] != nil);
    });

    return trialsAndPredictions;
}

+ (NSArray *)defaultTrials {
    return [self defaultTrialsAndPredictions][@"trials"];
}

+ (NSArray *)defaultPredictions {
    return [self defaultTrialsAndPredictions][@"predictions"];
}

@end
