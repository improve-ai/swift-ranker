//
//  IMPChooser.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

NS_ASSUME_NONNULL_BEGIN

@interface IMPChooser : NSObject

@property(readonly, nonatomic) MLModel *model;

+ (instancetype)chooserWithModelURL:(NSURL *)modelURL error:(NSError **)error;

- (instancetype)initWithModel:(MLModel *)model;

/**

 @returns Returns an array of NSNumber (double) objects.
 */
- (NSArray *)predicitonForArray:(MLMultiArray *)array;

/// Returns prediction for the given row or -1 if error.
- (double)singleRowPrediction:(NSArray<NSNumber*> *)features;

@end

NS_ASSUME_NONNULL_END
