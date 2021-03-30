//
//  IMPUtils.m
//  ImproveUnitTests
//
//  Created by PanHongxi on 3/23/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPUtils.h"
#import "XXHashUtils.h"

@implementation IMPUtils

// Source: https://stackoverflow.com/a/12948538/3050403
+ (double)gaussianNumber{
    double u1 = drand48();
    double u2 = drand48();
    double f1 = sqrt(-2 * log(u1));
    double f2 = 2 * M_PI * u2;
    return f1 * cos(f2);
}


/**
 * Generate n = variants.count random (double) gaussian numbers
 * Sort the numbers descending and return the sorted list
 * The median value of the list is expected to have a score near zero
 */
+ (NSArray *)generateDescendingGaussians:(NSUInteger) count {
    srand48(time(0));
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    for(int i = 0; i < count; ++i){
        [arr addObject:[NSNumber numberWithDouble:[IMPUtils gaussianNumber]]];
    }
    [arr sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 doubleValue] < [obj2 doubleValue];
    }];
    return [arr copy];
}

+ (NSString *)modelFileNameFromURL:(NSURL *)remoteURL {
    NSString *nameFormat = @"ai.improve.cachedmodel.%@.mlmodelc";
    const NSUInteger formatLen = [NSString stringWithFormat:nameFormat, @""].length;

    NSMutableCharacterSet *allowedChars = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowedChars addCharactersInString:@".-_ "];
    NSString *remoteURLStr = [remoteURL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:allowedChars];
    const NSUInteger urlLen = remoteURLStr.length;

    NSString *fileName;
    // NAME_MAX - max file name
    if (formatLen + urlLen <= NAME_MAX) {
        fileName = [NSString stringWithFormat:nameFormat, remoteURLStr];
    } else {
        const NSUInteger separLen = 2;
        const NSUInteger remainLen = NAME_MAX - formatLen - kXXHashOutputStringLength - separLen;
        const NSUInteger stripLen = urlLen - remainLen;

        NSMutableString *condensedURLStr = [NSMutableString new];
        [condensedURLStr appendString:[remoteURLStr substringToIndex:(remainLen / 2)]];
        [condensedURLStr appendString:@"-"];

        NSRange stripRange = NSMakeRange(remainLen / 2, stripLen);
        NSString *strip = [remoteURLStr substringWithRange:stripRange];
        NSString *encodedStrip = [XXHashUtils encode:strip];
        [condensedURLStr appendString:encodedStrip];
        [condensedURLStr appendString:@"-"];

        NSString *lastPart = [remoteURLStr substringFromIndex:urlLen - (remainLen + 1) / 2];
        [condensedURLStr appendString:lastPart];

        fileName = [NSString stringWithFormat:nameFormat, condensedURLStr];
    }

    return fileName;
}

@end
