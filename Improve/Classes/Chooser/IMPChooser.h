//
//  IMPChooser.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import <CoreML/CoreML.h>

@class IMPModelBundle;
@class IMPModelMetadata;

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

/// Used to convert column indexes to model feature names. Default: "f".
@property(copy, nonatomic) NSString *featureNamePrefix;

@property(copy, nonatomic) NSString *namespace;

@property(readonly, nonatomic) IMPModelMetadata *metadata;

+ (instancetype)chooserWithModelBundle:(IMPModelBundle *)bundle
                             namespace:(NSString *)namespace
                                 error:(NSError **)error;

- (instancetype)initWithModel:(MLModel *)model
                     metadata:(IMPModelMetadata *)metadata
                    namespace:(NSString *)namespace;

/**
 Choses a trial from the given variants. The trial is chosen according to the model predictions.
 @param variants A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @return A NSDictionary where keys are features similar to `varaiants`, and the values are the single choosen objects.
 */
- (id) choose:(NSArray *) variants
      context:(NSDictionary *) context;

- (NSArray *)sort:(NSArray *)variants
          context:(NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
