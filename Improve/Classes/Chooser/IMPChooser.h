//
//  IMPChooser.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>

@class IMPMatrix;

/**
A combination of subtractiong a constant and sigmoid. Intended to fix incorrect output from MLModel in order to make it the same
as output form XGBoost Booster.
*/
NS_INLINE double sigmfix(double x) {
    return 1. / (1. + exp(0.5 - x));
}

NS_ASSUME_NONNULL_BEGIN

@interface IMPChooser : NSObject

@property(readonly, nonatomic) MLModel *model;

@property(readonly, nonatomic) NSString *hashPrefix;

+ (instancetype)chooserWithModelURL:(NSURL *)modelURL
                              error:(NSError **)error;

- (instancetype)initWithModel:(MLModel *)model;

/**
 Choses a trial from the given variants. The trial is chosen according to the model predictions.
 @param variants A NSDictioary of NSArrays. Keys are feature names and arrays contain different options for the feature.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @return A NSDictionary where keys are features similar to `varaiants`, and the values are the single choosen objects.
 */
- (NSDictionary *)choose:(NSDictionary *)variants
                 context:(NSDictionary *)context;

- (NSArray<NSDictionary*> *)rank:(NSArray<NSDictionary*> *)variants
                         context:(NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
