//
//  IMPGivensProvider.h
//  ImproveUnitTests
//
//  Created by PanHongxi on 6/11/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IMPDecisionModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface IMPDeviceInfo : NSObject

@property (nonatomic, strong) NSString *model;

@property (nonatomic) int version;

@end

@interface IMPAppGivensProvider : GivensProvider

//+ (id)sharedInstance;

//- (NSDictionary *)getAllGivensWithExisted:(NSDictionary *)existedGivens;

@end

NS_ASSUME_NONNULL_END
