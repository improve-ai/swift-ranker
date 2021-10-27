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

@interface AppGivensProvider : GivensProvider

+ (instancetype)shared;

@end

NS_ASSUME_NONNULL_END
