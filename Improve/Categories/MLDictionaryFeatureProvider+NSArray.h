//
//  MLDictionaryFeatureProvider+NSArray.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/26/20.
//

#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface MLDictionaryFeatureProvider (NSArray)

/**
 Initializes dictionary with array values and keys in the following format: "prefix" + "index".
 */
- (instancetype)initWithArray:(NSArray *)array prefix:(NSString *)prefix error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
