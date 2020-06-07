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

+ (NSString *)randomStringWithLength:(NSInteger)length
{
    NSString *chars = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];

    for (int i = 0; i < length; i++) {
        NSUInteger randomIndex = arc4random() % [chars length];
        [randomString appendFormat:@"%C", [chars characterAtIndex:randomIndex]];
    }

    return randomString;
}

+ (NSString *)randomStringWithMinLength:(NSInteger)minLength maxLength:(NSInteger)maxLength {
    NSInteger length = minLength + (NSInteger)arc4random_uniform((uint32_t)maxLength);
    return [self randomStringWithLength:length];
}

@end
