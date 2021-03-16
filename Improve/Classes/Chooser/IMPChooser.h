//
//  IMPChooser.h
//  ImproveUnitTests
//
//  Created by Vladimir on 1/23/20.
//

#import <CoreML/CoreML.h>
#import "IMPFeatureEncoder.h"
#import "IMPModelMetadata.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPChooser : NSObject

@property(readonly, nonatomic) MLModel *model;
@property(readonly, nonatomic) IMPModelMetadata *metadata;
@property(readonly, nonatomic) IMPFeatureEncoder *featureEncoder;

- (instancetype)initWithModel:(MLModel *)model
                     metadata:(IMPModelMetadata *)metadata;

/**
 Choses a trial from the given variants. The trial is chosen according to the model predictions.
 @param variants A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @return A NSDictionary where keys are features similar to `varaiants`, and the values are the single choosen objects.
 */
- (nullable id) choose:(NSArray *) variants
               context:(nullable NSDictionary *) context;

- (NSArray *)sort:(NSArray *)variants
          context:(nullable NSDictionary *)context;

/**
 Takes an array of variants and context and returns an array of NSNumbers of the scores.
 */
- (NSArray *) score:(NSArray *)variants
            context:(nullable NSDictionary *)context;

@end

NS_ASSUME_NONNULL_END
