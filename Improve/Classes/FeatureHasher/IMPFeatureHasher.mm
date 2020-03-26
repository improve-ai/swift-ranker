//
//  IMPFeatureHasher.m
//  FeatureHasher
//
//  Created by Vladimir on 1/16/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import "IMPFeatureHasher.h"
#import "IMPMurmurHash.h"
#import "IMPJSONFlattener.h"
#import "IMPModelMetadata.h"


@implementation IMPFeatureHasher

- (instancetype)initWithTable:(NSArray *)table seed:(uint32_t)seed
{
    self = [super init];
    if (self) {
        _table = table;
        _modelSeed = seed;
    }
    return self;
}

- (instancetype)initWithMetadata:(IMPModelMetadata *)metadata
{
    return [self initWithTable:metadata.lookupTable seed:metadata.seed];
}

- (NSUInteger)columnCount {
    return [self.table[1] count];
}

- (IMPFeaturesDictT *)encodeFeatures:(NSDictionary *)properties
{
    return [self encodeFeaturesFromFlattened:[IMPJSONFlattener flatten:properties
                                                             separator:@"\0"]];
}

- (IMPFeaturesDictT *)encodePartialFeaturesWithKey:(NSString *)propertyKey
                                           variant:(NSDictionary *)variant
{
    return [self encodeFeatures:@{propertyKey: variant}];
}

- (IMPFeaturesDictT *)encodeFeaturesFromFlattened:(NSDictionary *)flattenedProperties
{
    NSMutableDictionary<NSNumber*, NSNumber*> *features = [NSMutableDictionary new];
    double noise = [self generateRandomNoise];

    for (NSString *featureName in flattenedProperties)
    {
        NSUInteger column = [self lookupColumnInTable:self.table
                                              withKey:featureName
                                                 seed:self.modelSeed
                                                    w:1];
        id value = flattenedProperties[featureName];
        if ([value isKindOfClass:NSNumber.class]) {
            // Encode BOOL and int as double
            features[@(column)] = @([value doubleValue]);
        } else if ([value isKindOfClass:NSString.class]) {
            NSString *string = value;
            features[@(column)] = @([self lookupValueForColumn:column
                                                        string:string
                                                          seed:self.modelSeed
                                                         noise:noise]);
        } else {
            continue;
        }
    }

    return features;
}

- (double)generateRandomNoise {
    // Just a stub
    // Source: https://stackoverflow.com/a/12948538/3050403
    double u1 = drand48();
    double u2 = drand48();
    double f1 = sqrt(-2 * log(u1));
    double f2 = 2 * M_PI * u2;
    return f1 * cos(f2);
}

- (NSInteger)lookupColumnInTable:(NSArray *)table
                         withKey:(NSString *)key
                            seed:(uint32_t)seed
                               w:(uint32_t)w
{
    NSArray *t0 = table[0];
    int c = [t0[[IMPMurmurHash hash32:key withSeed:seed] % t0.count] intValue];
    return (c < 0 ? ABS(c)-1 : [IMPMurmurHash hash32:key withSeed:(uint32_t)c^seed]) % ([(NSArray *)table[1] count]/w);
}

- (double)lookupValueForColumn:(NSInteger)column
                        string:(NSString *)string
                          seed:(uint32_t)seed
                         noise:(double)noise
{
    NSArray *t = self.table[1][column];
    NSArray *t1 = t[1];
    NSInteger c = [self lookupColumnInTable:t withKey:string seed:seed w:2]*2;
    return [t1[c] doubleValue]+[t1[c+1] doubleValue]*noise;
}

- (NSArray<IMPFeaturesDictT*> *)batchEncode:(NSArray<NSDictionary*> *)properties
{
    NSMutableArray *batchEncoded = [NSMutableArray arrayWithCapacity:properties.count];
    for (NSDictionary *propertiesDict in properties) {
        [batchEncoded addObject:[self encodeFeatures:propertiesDict]];
    }
    return batchEncoded;
}

@end
