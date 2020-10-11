//
//  IMPJSONUtils.h
//  MachineLearning
//
//  Created by Vladimir on 1/21/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPJSONUtils : NSObject

+ (nullable id)objectFromString:(NSString *)jsonString;

+ (nullable id)objectFromString:(NSString *)jsonString error:(NSError **)error;

/// Tries to convert the object to JSON, otherwise returns the description + error message. For debug purposes.
+ (NSString *)jsonStringOrDerscriptionOf:(NSObject *)object;

/**
 Tries to convert the object to JSON, otherwise returns the description + error message. For debug purposes.
 @param object An object to convert into string.
 @param condensed If YES - outputs string without newlines
 @returns A string describing the object.
 */
+ (NSString *)jsonStringOrDerscriptionOf:(NSObject *)object
                               condensed:(BOOL)condensed;

@end

NS_ASSUME_NONNULL_END
