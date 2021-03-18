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
 @param variants A JSON encodeable list of variants to choose from.  May contain values of type NSDictionary, NSArray, NSString, NSNumber, and NSNull.  NSDictionary keys must be of type NSString. NaN and infinity values are not allowed for NSNumber because they are not JSON encodable.
 @param context A NSDictioary of universal features, which may affect prediction but not inclued into the ouptput.
 @return an array of scores
 */
- (NSArray <NSNumber *>*) score:(NSArray *)variants
                          given:(nullable NSDictionary <NSString *, id>*)context;

@end

NS_ASSUME_NONNULL_END
