//
//  IMPDelegate.h
//  ImproveUnitTests
//
//  Created by Vladimir on 4/30/20.
//  Copyright © 2020 Mind Blown Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Improve;

NS_ASSUME_NONNULL_BEGIN

@protocol IMPDelegate <NSObject>
@optional

- (void)improveDidLoadModels:(Improve *)improve;

- (void)improve:(Improve *)improve
      didChoose:(NSDictionary *)chosenVariants
   fromVariants:(NSDictionary *)variants
      forDomain:(NSString *)domain
        context:(NSDictionary *)context;

- (void)improve:(Improve *)improve
        didRank:(NSArray *)rankedVariants
      forDomain:(NSString *)domain
        context:(NSDictionary *)context;

- (BOOL)improve:(Improve *)improve shouldTrack:(NSMutableDictionary *)event;

- (void)improve:(Improve *)improve
       didTrack:(NSDictionary *)event;

@end

NS_ASSUME_NONNULL_END
