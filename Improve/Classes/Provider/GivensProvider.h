//
//  GivensProvider.h
//  Tests
//
//  Created by PanHongxi on 10/27/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GivensProvider : NSObject

/**
 * Subclasses of the GivensProvider must overwrite this method to provide custom givens.
 *
 * @return A dictionary that will be passed to the FeatureEncoder aside a variant to obtain the
 * feature vector of the latter. And the feature vector will eventually be fed to a CoreML model to
 * calculate the score of the variant. Only NSString/NSNumber or a nested array/dict of these types allowed
 * for the dictionary value; otherwise, a runtime exception would later be thrown while calculating the
 * feature vector of a variant.
 */
- (NSDictionary<NSString *, id> *)givensForModel:(NSString *)modelName;

@end


NS_ASSUME_NONNULL_END
