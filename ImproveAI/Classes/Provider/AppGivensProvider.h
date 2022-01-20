//
//  AppGivensProvider.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 10/27/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GivensProvider.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPDeviceInfo : NSObject

@property (nonatomic, strong) NSString *model;

@property (nonatomic, strong) NSDecimalNumber *version;

@end

@interface AppGivensProvider : GivensProvider

+ (instancetype)shared;

+ (void)addReward:(double)model forModel:(NSString *)modelName;

@end

NS_ASSUME_NONNULL_END
