# improve.ai iOS SDK

## AI-Powered Conversion Optimization & Revenue Optimization
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Use machine learning to build apps that improve themselves to maximize conversions and revenue. (Revenue optimization is an optional add-on).

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Improve"
```
### Hello World!


For "Hello World!" we'll continuously optimize the ```greeting``` property to automatically discover which one provides the best user retention and revenue.  This is like A/B testing on AI steroids.

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

Visit [improve.ai](http://improve.ai) to sign up for an api key.

This is where the magic happens - let improve.ai choose the `greeting` most likely to lead to conversion.

```objc
[[Improve instance] chooseFrom:variants block:^(NSDictionary *) properties {
    // properties contains the chosen values
}];

```

After choosing a variant, improve.ai needs to learn how that variant performs.  When the greeting becomes *causal*, track an event and include the chosen variant as a property on that event.  (Note that timing based properties may become causal the moment they are chosen.)

```objc
[[Improve instance] trackUsing:@{ @"greeting": greeting }];

```

// Whenever there is a conversion
[[Improve instance] trackRevenue:@19.99];

```

That's all there is to it.  Forever more improve.ai will learn the greeting that earns the most revenue.  

For further documentation see [improve.ai](https://docs.improve.ai).

## License

The improve.ai iOS SDK is available under the MIT license. See the LICENSE file for more info.  Use of improve.ai is subject to its license agreement.
