# Improve.ai iOS SDK

## An AI Library for Making Great Choices
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Use machine learning to quickly choose and sort data to maximize rewards such as user retention, performance, or revenue.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Improve"
```

## Import and initialize the SDK.

```objc
#import Improve.h

[Improve instanceWithModelBundleURL:@"URL to model bundle" apiKey:@"YOUR API KEY"];

```

### Hello World!

```objc
Improve *improve = [Improve instance];

NSString *greeting = [improve choose:@[@"Hello World!", @"Hi World!", @"Howdy World!"]];

// ... later when a button is clicked or product purchased

[improve trackReward:@1.0];
```

Improve learns to track the greeting with the highest expected reward.

### Howdy World (Context for Cowboys)

```objc
NSString *greeting = [improve choose:@[@"Hello World!", @"Hi World!", @"Howdy World!"] context:@{@"language": @"cowboy"}];
```
Improve can optimize decisions for a given context of arbitrary complexity.

### Numbers Too

```objc
NSNumber *discount = [improve choose:@[@0.10, @0.20, @0.30] context:@{@"campaign": @"google"}];
```

### Complex Objects

```objc
NSArray *themeVariants = @[ @{ @"textColor": @"#000000", @"backgroundColor": @"#ffffff" },
                            @{ @"textColor": @"#F0F0F0", @"backgroundColor": @"#aaaaaa" } ]
                            
NSDictionary *theme = [improve choose:themeVariants];
```

Improve learns to use the attributes of each key and value in a dictionary variant to make the optimal decision.  Variants can be any JSON encodeable object of arbitrary complexity.

### Sort Stuff

```objc
// No human could ever make this decision, but math can.
NSArray *sortedDogs = [improve sort:@[@"German Shepard", @"Border Collie", @"Labrador Retriever"]];
```

### Organize Decisions with Domains
```objc

NSNumber *discount = [improve choose:@[@0.10, @0.20, @0.30] context:@{@"campaign": @"google"} domain:@"discounts"];

// ...later
[improve trackRewards:@{ @"discounts": @19.99 };
```

Domains ensure that multiple uses of Improve in the same project are decided and trained seperately.  A domain can be a simple string like "discounts" or can be more complicated like "SubscriptionViewController.buttonText".  Domain strings are opaque and can be any format you wish.

When using domains the reward must be tracked for that specific domain.

### Learning from Specific Types of Rewards

```objc
 NSString *backgroundSong = [improve choose:@[songA, songB] context:context domain:@"songs" rewardKey:@"session_length"];
 
 // ...on app exit
 [improve trackRewards:@{ @"session_length": sessionLength];
 ```
 
 ### Learning Rewards for a Specific Variant
 
 Instead of applying rewards to general categories of decisions, they can be scoped to specific variants by specifying a custom rewardKey for each variant.

```objc
 // Disable autotrack for this choose: call because we don't yet know the chosen variant
 NSDictionary *viralVideo = [improve choose:@[videoA, videoB] context:context domain:@"videos" autoTrack:@NO];
 
 // Create a custom rewardKey specific to this variant
 NSString rewardKey = [@"shared:" stringByAppendingString:[viralVideo objectForKey:@"videoId"]];
 
 // Track the chosen variant along with its custom rewardKey
 [improve trackChosen:viralVideo context:context domain:@"videos" rewardKey:rewardKey];
 
 // ...later when a video is shared
 [improve trackRewards:@{ rewardKey: @1.0 }];
 ```
 
 ### Server-Side Decision/Rewards Processing
 
 Some deployments may wish to handle all rewards assignments on the server side during model training. In this case, you may simply track generic app events to be parsed by your custom backend scripts.
 
 ```objc
 // Probably disable auto tracking since it will all be handled by the back end.
 NSString *song = [improve choose:@[songA, songB] context:context domain:@"songs" autoTrack:@NO];

 //...later when the song is played
 [improve trackAnalyticsEvent:@"Song Played" properties:@{@"song": song}];

 ```

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
