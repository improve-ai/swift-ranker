//
//  IMPJSONFlattener.h
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPJSONFlattener : NSObject

+ (NSData * _Nullable)flatten:(NSData *)jsonData
                    separator:(NSString *)separator
                        error:(NSError * _Nullable *)error;

/**
 Flattens inner collections (NSArray, NSDictionary) of a json object.
 @param separator The separator used to compose the output keys.
 @return The flat JSON dictionary where keys are key paths in terms of original object.
 */
+ (NSDictionary * _Nullable)flatten:(id)jsonObject
                          separator:(NSString *)separator;

/// The default separator is "_"
+ (NSDictionary * _Nullable)flatten:(id)jsonObject;

@end

NS_ASSUME_NONNULL_END
