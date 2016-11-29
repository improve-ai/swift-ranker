# improve.ai - Self-Improving App iOS SDK

[![CI Status](http://img.shields.io/travis/Justin Chapweske/Improve.svg?style=flat)](https://travis-ci.org/Justin Chapweske/Improve)
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)


## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "Improve"
```

### Hello World!

improve.ai enables apps to optimize their own event funnels.  For our "Hello World" we'll do continuous improvement on a funnel going from *Viewed* to *Clicked*.  This use case is similar to A/B testing except it is fully automated with no human intervention and new variants can be added at any time.

First we simply import and initialize the SDK.

```objc
#import Improve.h

[Improve sharedInstanceWithApiKey:@"YOUR API KEY"];

```

Visit [improve.ai](http://improve.ai) to sign up for an api key.

Let's set up our funnel and greeting choices.

```objc
NSArray *funnel = [@"Viewed", @"Clicked"];

NSString *greeting = @"Hello World"; // the default greeting

NSArray *greetingChoices = [@"Hello World!", @"Hi World!", @"Howdy World!"]; // other possible greetings

```

This is where the magic happens - let improve.ai choose the best *greeting* given the choices and funnel:

```objc
Improve *improve = [Improve sharedInstance];
[improve chooseFrom:choices forKey:@"greeting" funnel:funnel block:^(NSString* result) {
  greeting = result;
}];

```
Elsewhere in our code, when the greeting is viewed, we track the event so improve.ai can learn.

```objc
[improve track:@"Viewed" properties:@{ @"greeting": greeting }];

```

Likewise with *Clicked*.

```objc
[improve track:@"Clicked" properties:@{ @"greeting": greeting }];

```

That's all there is to it.  Forever more improve.ai will learn and optimize the greeting to maximize the probability of going from *Viewed* to *Clicked*.  With each new user the app will improve, without you having to actively manage the process.


## Author

Justin Chapweske, justin@improve.ai

## License

The improve.ai iOS SDK is available under the MIT license. See the LICENSE file for more info.
