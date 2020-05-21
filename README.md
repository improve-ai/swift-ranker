# Improve.ai iOS SDK

## An AI Library for Making Great Choices Fast
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Use machine learning to quickly choose and sort data to maximize rewards such as user retention, performance, or revenue.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install, add the following line to your Podfile:

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

button.text = [improve choose:@[@"Hello World!", @"Hi World!", @"Howdy World!"]];

// ... later when the button is tapped

[improve trackReward:@1.0];
```

Improve learns to track the greeting with the highest expected reward.

### Numbers Too

```objc
NSNumber *bonusOfferGems = [improve choose:@[@1000, @2000, @3000]];

// ... later when a purchase is made

[improve trackReward:revenue];
```

### Complex Objects

```objc
NSArray *themeVariants = @[ @{ @"textColor": @"#000000", @"backgroundColor": @"#ffffff" },
                            @{ @"textColor": @"#F0F0F0", @"backgroundColor": @"#aaaaaa" } ]
                            
NSDictionary *theme = [improve choose:themeVariants];
```

Improve learns to use the attributes of each key and value in a dictionary variant to make the optimal decision.  Variants can be any JSON encodeable object of arbitrary complexity.

### Howdy World (Context for Cowboys)

```objc
button.text = [improve choose:@[@"Hello World!", @"Hi World!", @"Howdy World!"] context:@{@"language": @"cowboy"}];
```
Improve can optimize decisions for a given context of arbitrary complexity.


### Sort Stuff

```objc
// No human could ever make this decision, but math can.
NSArray *sortedDogs = [improve sort:@[@"German Shepard", @"Border Collie", @"Labrador Retriever"]];
```

* sort calls are not automatically tracked

### Organize Decisions with Domains
```objc

NSNumber *discount = [improve choose:@[@0.10, @0.20, @0.30] context:context domain:@"discounts"];

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
 
 ## Security & Privacy
 
 Improve uses tracked variants, context, and rewards to continuously train statistical models.  If models will be distributed to unsecured clients, then the most conservative stance is to assume that what you put into the model you can get out.
 
 That said, all variant and context keys and values are hashed (using a secure pseudorandom function once siphash is deployed) and never transmitted in models so if a sensitive information were accidentally included in tracked data, it is not exposed by the model.
 
It is strongly recommended to never include Personally Identifiable Information (PII) in an Improve variant or context if for no other reason than to ensure that it is not persisted in analytics records on your server instances.
 
 The types of information that can be gleaned from an Improve model are the types of things it is designed for, such as the relative ranking and scoring of variants and contexts, and the relative frequency of variants and contexts.  Future versions will normalize rewards to zero, so absolute information about rewards will not be transmitted at that time.
 
 Additional security measures such as white-listing specific variants and context or obfuscating rewards can be implemented by custom scripts on the back end.
 
 For truly sensitive model information, you may wish to only use those Improve models within a secure server environment and only distribute final decisions to clients.
 
 ## Additional Caveats
 
 Use of rapidly changing data in variants and contexts is discouraged.  This includes timestamps, counters, random numbers, message ids, or unique identifiers.  These will be treated as statistical noise and may slow down model learning or performance.  If models become bloated you may filter such nuisance data on the server side during training time.
 
 Numbers with limited range, such as ratios, are okay as long as they are encoded as NSNumbers.
 
 In addition to the previous noise issue, linear time based data is generally discouraged because decisions will always being made in a time interval ahead of the training data.  If time based context must be used then ensure that it is cyclical such as the day of the week or hour of the day without reference to an absolute time.

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
