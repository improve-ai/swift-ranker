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

// The separator used to compose the output keys. Default is empty string.
@property(nonatomic, copy) NSString *separator;

@property(nonatomic, strong, nullable) id emptyArrayValue;

@property(nonatomic, strong, nullable) id emptyDictionaryValue;

- (NSData * _Nullable)flatten:(NSData *)jsonData
                        error:(NSError * _Nullable *)error;

- (NSDictionary * _Nullable)flatten:(id)jsonObject;

@end

NS_ASSUME_NONNULL_END
