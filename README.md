# Improve.ai for iOS

## An AI Library for Making Great Choices
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Quickly choose and sort objects to maximize user retention, performance, revenue, or any other metric. It's like an AI if/then statement.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install, add the following line to your Podfile:

```ruby
pod "Improve"
```

## Import and initialize the SDK.

Do this once in your AppDelegate.

```objc
#import Improve.h

Improve *improve = [Improve instanceWithApiKey:@"YOUR API KEY"];

improve.modelBundleUrl = @"YOUR MODEL BUNDLE URL"; // fetches the bundle using the api key
improve.trackUrl = @"YOUR MODEL GATEWAY TRACK ENDPOINT";

```

To obtain the model bundle URL and api key, first deploy a Improve Model Gateway (link).

### Hello World!

What is the best greeting?

```objc
Improve *improve = [Improve instance];

// get the decision
button.text = [improve choose:@"greeting" variants:@[ @"Hello World!", @"Hi World!", @"Howdy World!" ]];

// train the model using the decision
[improve trackDecision:@"greeting" variant:button.text];

// ... later when the button is tapped, give the decision a reward
[improve trackReward:@"greeting" value:@1.0];
```

Improve quickly learns to choose the greeting with the highest chance of button tap.

```@"greeting"``` in this example is the namespace for the type of variant being chosen. Namespaces ensure that multiple uses of Improve in the same project are decided and trained seperately.  A namespace can be a simple string like "discount" or "song" or can be more complicated like "SubscriptionViewController.buttonText".  Namespace strings are opaque and can be any format you wish.

### Numbers Too

How many bonus gems should we offer on our In App Purchase?

```objc
NSNumber *bonusGems = [improve choose:@"bonusGems" variants:@[ @1000, @2000, @3000 ]];

// train the model using the decision
[improve trackDecision:@"bonusGems" variant:bonusGems];

// ... later when the user makes a purchase, give the decision a reward
[improve trackReward:@"bonusGems" value:revenue];
```

### Complex Objects

```objc
NSArray *themeVariants = @[ @{ @"textColor": @"#000000", @"backgroundColor": @"#ffffff" },
                            @{ @"textColor": @"#F0F0F0", @"backgroundColor": @"#aaaaaa" } ];
                            
NSDictionary *theme = [improve choose:@"theme" variants:themeVariants];
```

Improve learns to use the attributes of each key and value in a dictionary variant to make the optimal decision.  

Variants can be any JSON encodeable object of arbitrary complexity.

### Howdy World (Context for Cowboys)

If language is "cowboy", which greeting is best?

```objc
NSArray *greetings = @[ @"Hello World!", @"Hi World!", @"Howdy World!" ];

button.text = [improve choose:@"greeting" variants:greetings context:@{ @"language": @"cowboy" }];
```

Improve can optimize decisions for a given context of arbitrary complexity. We might imagine that "Howdy World!" would produce the highest rewards for { language: cowboy }, while another greeting might be best for other contexts.

You can think of contexts like: If `<context>` then `<variant>`.

### Learning from Specific Types of Rewards
Instead of having to manually track rewards for every seperate decision namespace, we can assign a custom rewardKey during trackDecision for that specific decision to be trained on.

```objc
 [improve trackDecision:@"song" variant:@"Hey Jude" context:context rewardKey:@"session_length"];
 
 // ...on app exit
 [improve trackRewards:@{ @"session_length": sessionLength];
 ```
 
 ### Learning Rewards for a Specific Variant
 
 Instead of applying rewards to general categories of decisions, they can be scoped to specific variants by specifying a custom rewardKey for each variant.

```objc

 NSDictionary *viralVideo = [improve choose:@"viralVideo" variants:@[ videoA, videoB ]];
 
 // Create a custom rewardKey specific to this variant
 NSString rewardKey = [@"Video Shared.id=" stringByAppendingString:[viralVideo objectForKey:@"videoId"]];
 
 // Track the chosen variant along with its custom rewardKey
 [improve trackDecision:"viralVideo" variant:viralVideo context:context rewardKey:rewardKey];
 
 // ...later when a video is shared
 [improve trackReward:rewardKey value:@1.0];
 
 
 ```
 
 ### Sort Stuff

```objc
// No human could ever make this decision, but math can.
NSArray *sortedDogs = [improve sort:@"dogs" variants:@[ @"German Shepard", @"Border Collie", @"Labrador Retriever" ]];


// With sort, training is done just as before, on one individual variant at a time.
NSString *dog = [sortedDogs objectAtIndex:0];
[improve trackDecision:@"dogs" variant:dog context:nil rewardKey:dog];

// ... 
[improve trackReward:dog value:@1000];
```

Sort is handy for building personalized feeds or reducing huge lists of variants down to smaller lists for future contextual choose calls.  It is recommended to pass a context to sort that is similar to contexts the model was trained on.
 
 ### Server-Side Decision/Rewards Processing
 
 Some deployments may wish to handle all training and reward assignements on the server side. In this case, you may simply track generic app events to be parsed by your custom backend scripts and converted to decisions and rewards.
 
 ```objc
 // omit trackDecision and trackReward on the client and use custom code on the model gateway to do it instead

 //...when the song is played
 [improve trackAnalyticsEvent:@"Song Played" properties:@{ @"song": song }];

 ```
 
 ## Algorithm
 
The algorithm is a production tuned contextual multi-armed bandit algorithm related to Thompson Sampling.
 
 ## Security & Privacy
 
 Improve uses tracked variants, context, and rewards to continuously train statistical models.  If models will be distributed to unsecured clients, then the most conservative stance is to assume that what you put in the model you can get out.
 
 That said, all variant and context data is hashed (using a secure pseudorandom function once siphash is deployed) and never transmitted in models so if a sensitive information were accidentally included in tracked data, it is not exposed by the model.
 
It is strongly recommended to never include Personally Identifiable Information (PII) in an Improve variant or context if for no other reason than to ensure that it is not persisted in your Improve Model Gateway analytics records.
 
 The types of information that can be gleaned from an Improve model are the types of things it is designed for, such as the relative ranking and scoring of variants and contexts, and the relative frequency of variants and contexts.  Future versions will normalize rewards to zero, so absolute information about rewards will not be transmitted at that time.
 
 Additional security measures such as white-listing specific variants and context or obfuscating rewards can be implemented by custom scripts on the back end.
 
 For truly sensitive model information, you may wish to only use those Improve models within a secure server environment.
 
 ## Additional Caveats
 
 Use of rapidly changing data in variants and contexts is discouraged.  This includes timestamps, counters, random numbers, message ids, or unique identifiers.  These will be treated as statistical noise and may slow down model learning or performance.  If models become bloated you may filter such nuisance data on the server side during training time.
 
 Numbers with limited range, such as ratios, are okay as long as they are encoded as NSNumbers.
 
 In addition to the previous noise issue, linear time based data is generally discouraged because decisions will always being made in a time interval ahead of the training data.  If time based context must be used then ensure that it is cyclical such as the day of the week or hour of the day without reference to an absolute time.

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
