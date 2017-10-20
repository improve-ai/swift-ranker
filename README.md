# improve.ai iOS SDK

## AI-Powered App Configuration & Revenue Optimization
 
[![CI Status](http://img.shields.io/travis/Justin Chapweske/Improve.svg?style=flat)](https://travis-ci.org/Justin Chapweske/Improve)
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Improve.ai helps you build apps that improve themselves, automatically, to maximize user retention and revenue.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Improve"
```
### Hello World!


For "Hello World!" we'll continuously optimize the ```greeting``` property to automatically discover which one provides the best user retention and revenue.  This is like A/B testing on steroids.

```objc
NSString *variants = @{
                         @"greeting": [
                             @"Hello World!",
                             @"Hi World!",
                             @"Howdy World!"
                         ]
                     };
```

Variants may be hard coded as above, or loaded from a .plist, database query, or remote configuration service.  Up to 1,000 variants may be provided per property and new variants can be added at any time.

Import and initialize the SDK.

```objc
#import Improve.h

[Improve instanceWithApiKey:@"YOUR API KEY"];

```

Visit [improve.ai](http://improve.ai) to sign up for a free api key.

This is where the magic happens - let improve.ai choose the `greeting` most likely to give the best revenue or user retention.

```objc
[[Improve instance] chooseFrom:variants block:^(NSDictionary *) properties {
    // properties contains the chosen values
}];

```

After choosing a variant, improve.ai needs to learn how that variant performs.  When the greeting is *Viewed*, track the event.

```objc
[[Improve instance] track:@"Viewed" properties:@{ @"greeting": greeting }];

```

By default, improve.ai will optimize for user retention and revenue.  Track events for both.

```objc
// In applicationDidBecomeActive
[[Improve instance] track:@"App Active" properties:nil];

...

// Whenever there is a purchase
[[Improve instance] track:@"Purchased" properties:@{ @"revenue": @19.99 }]

```

That's all there is to it.  Forever more improve.ai will learn the greeting that earns the most revenue.  If revenue is not tracked, it will fall back to optimizing for user retention.

For more complicated data structures than simple key/value properties and alternate goals, use the *withConfig:config* version of *chooseFrom*.  Visit [the docs](https://docs.improve.ai) for more information on the format of variant_config.

```objc
[[Improve instance] chooseFrom:variants withConfig:config block:^(NSDictionary *) properties {
// properties contains the chosen values
}];
```

For further documentation see [improve.ai](https://docs.improve.ai).

## Author

Justin Chapweske, justin@improve.ai

## License

The improve.ai iOS SDK is available under the MIT license. See the LICENSE file for more info.
