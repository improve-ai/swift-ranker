//
//  IMPMatrixBatchProvider.m
//  ImproveUnitTests
//
//  Created by Vladimir on 2/6/20.
//

#import "IMPMatrixBatchProvider.h"
#import "IMPMatrix.h"


#pragma mark IMPMatrixRowFeatureProvider
/**
 A MLFeatureProvider returned by IMPMatrixBatchProvider. Provides access by names for a single row of a IMPMatrix.
 */
@interface IMPMatrixRowFeatureProvider: NSObject<MLFeatureProvider>

@property(readonly, nonatomic) IMPMatrix *matrix;

@property(readonly, nonatomic) NSUInteger row;

/// The default value is "f"
@property(copy, nonatomic) NSString *prefix;

- (instancetype)initWithMatrix:(IMPMatrix *)matrix row:(NSUInteger)row;

@end

@implementation IMPMatrixRowFeatureProvider

@synthesize featureNames = _featureNames;

- (instancetype)initWithMatrix:(IMPMatrix *)matrix row:(NSUInteger)row
{
    self = [super init];
    if (self) {
        _matrix = matrix;
        _row = row;
        _prefix = @"f";
    }
    return self;
}

- (nullable MLFeatureValue *)featureValueForName:(nonnull NSString *)featureName
{
    NSInteger column = [[featureName substringFromIndex:self.prefix.length] integerValue];
    double rawVal = [self.matrix valueAtRow:self.row column:column];
    if (isnan(rawVal)) {
        return [MLFeatureValue undefinedFeatureValueWithType:MLFeatureTypeDouble];
    }
    MLFeatureValue *value = [MLFeatureValue featureValueWithDouble:rawVal];
    return value;
}

@end

#pragma mark IMPMatrixBatchProvider
@implementation IMPMatrixBatchProvider

- (instancetype)initWithMatrix:(IMPMatrix *)matrix
{
    self = [super init];
    if (self) {
        _matrix = matrix;
        _featureNamePrefix = @"f";
    }
    return self;
}

- (NSInteger)count {
    return self.matrix.rows;
}

- (nonnull id<MLFeatureProvider>)featuresAtIndex:(NSInteger)index
{
    IMPMatrixRowFeatureProvider *provider = [[IMPMatrixRowFeatureProvider alloc] initWithMatrix:self.matrix row:index];
    provider.prefix = self.featureNamePrefix;
    return provider;
}

@end



