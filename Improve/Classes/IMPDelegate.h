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
      forAction:(NSString *)action
        context:(NSDictionary *)context;

- (void)improve:(Improve *)improve
        didRank:(NSArray *)rankedVariants
      forAction:(NSString *)action
        context:(NSDictionary *)context;

//- (void)improve:(Improve *)improve
//      willTrack:(NSString *)event
//           body:(NSDictionary *_Nullable*_Nullable)eventBody;

//- (void)improve:(Improve *)improve
//       didTrack:(NSString *)event
//           body:(NSDictionary *)eventBody;

@end

NS_ASSUME_NONNULL_END
