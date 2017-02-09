# improve.ai - Continuous Conversion Optimization + Pricing Optimization iOS SDK
 
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

This example teaches the core concepts of *Properties*, *Choices*, *Events*, and *Funnels*.  

For "Hello World!" we'll continuously optimize the ```greeting``` property.  This is like A/B testing on steroids.

```objc
NSString *greeting = @"Hello World!";
```

```Hello World``` will be the default value.  This could be used immediately or in the case of a network error.

Now, create some alternate greetings:

```objc
NSArray *choices = [@"Hello World!", @"Hi World!", @"Howdy World!"];
```

Typically the choices would be loaded from a database query or configuration file.  Up to 1,000 choices could be provided and new choices can be added at any time.  

Now specify the goal to optimize for using an event *funnel*.  A *funnel* can be thought of as a goal path or sequence of events that you want to occur.  In this case the funnel goes from *Viewed* to *Clicked*.  This learns the greeting most likely to be clicked.

```objc
NSArray *funnel = [@"Viewed", @"Clicked"];
```

Import and initialize the SDK.

```objc
#import Improve.h

[Improve sharedInstanceWithApiKey:@"YOUR API KEY"];

```

Visit [improve.ai](http://improve.ai) to sign up for an api key.

This is where the magic happens - let improve.ai choose the `greeting` most likely to be *Clicked*:

```objc
Improve *improve = [Improve sharedInstance];
[improve chooseFrom:choices forKey:@"greeting" funnel:funnel block:^(NSString* result) {
    greeting = result;
}];

```

 - ```choices``` the list of possible property values
 - ```greeting``` the property key to optimize
 - ```funnel``` the goal path
 - ```result``` the decision from improve.ai

Lastly, improve.ai needs to learn how the different property values perform.  When the greeting is *Viewed*, track the event.

```objc
[improve track:@"Viewed" properties:@{ @"greeting": greeting }];

```

Likewise with *Clicked*.

```objc
[improve track:@"Clicked" properties:@{ @"greeting": greeting }];

```

That's all there is to it.  Forever more improve.ai will learn the greeting most likely to be to *Clicked*.  With each new user the app will improve, without you having to actively manage the process.

For further documentation see [improve.ai](https://www.improve.ai).

## Author

Justin Chapweske, justin@improve.ai

## License

The improve.ai iOS SDK is available under the MIT license. See the LICENSE file for more info.
