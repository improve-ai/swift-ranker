//
//  MLDictionaryFeatureProvider+NSArray.m
//  ImproveUnitTests
//
//  Created by Vladimir on 1/26/20.
//

#import "MLDictionaryFeatureProvider+NSArray.h"

@implementation MLDictionaryFeatureProvider (NSArray)

- (instancetype)initWithArray:(NSArray *)array prefix:(NSString *)prefix error:(NSError **)error
{
  NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:array.count];
  for (NSInteger i = 0; i < array.count; i++)
  {
    NSString *key = [NSString stringWithFormat:@"%@%ld", prefix, i];
    values[key] = array[i];
  }

  self = [self initWithDictionary:values error:error];
  return self;
}

@end
