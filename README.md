# Improve AI for iOS

## Fast AI Decisions for iOS, Android, and the Cloud
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

Quickly make decisions that maximize user retention, performance, revenue, or any other metric. It's like an AI if/then statement.

Improve.ai performs fast AI decisions on any JSON encodable data structure including dictionaries, arrays, strings, numbers, and booleans.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install, add the following line to your Podfile:

```ruby
pod "Improve"
```

### Hello World!

What is the best greeting?

```swift

greeting = DecisionModel.load(modelUrl).chooseFrom([“Hello World”, “Howdy World”, “Hi World”]).given({“language”: “cowboy”}).get()
```

### Numbers Too

What discount should we offer today?

```swift

discount = DecisionModel.load(modelUrl).chooseFrom([.1, .2, .3]).get()

```

### Complex Objects

```swift
NSArray *themeVariants = [ { "textColor": "#000000", "backgroundColor": "#ffffff" },
                            { "textColor": "#F0F0F0", "backgroundColor": "#aaaaaa" } ];
                            
theme = decisionModel.chooseFrom(themeVariants).get()

```

Improve learns to use the attributes of each key and value in a dictionary variant to make the optimal decision.  

Variants can be any JSON encodeable object of arbitrary complexity.

### Howdy World (Context for Cowboys)

If language is "cowboy", which greeting is best?

```objc
NSArray *greetings = @[ @"Hello World!", @"Hi World!", @"Howdy World!" ];

button.text = [improve choose:greetings context:@{ @"language": @"cowboy" }];
```

Improve can optimize decisions for a given context of arbitrary complexity. We might imagine that "Howdy World!" would produce the highest rewards for { language: cowboy }, while another greeting might be best for other contexts.

You can think of contexts like: If `<context>` then `<variant>`.
 
 ### Sort Stuff

```objc
// No human could ever make this decision, but math can.
NSArray *sortedDogs = [improve sort:@[@"German Shepard", @"Border Collie", @"Labrador Retriever"] context:context];


// With sort, training is done just as before, on one individual variant at a time.
NSString *topDog = [sortedDogs objectAtIndex:0];
[improve trackDecision:topDog context:context rewardKey:@"dog"];

// ... 
[improve addReward:@1000 forKey:@"dog"];
```

Sort is handy for building personalized feeds or reducing huge lists of variants down to smaller lists for future contextual choose calls.  It is recommended to pass a context to sort that is similar to contexts the model was trained on.

## Training

TODO

## Bootstrapping a New Model

TODO
```
model = new DecisionModel("themes")
model.tracker = foo

DecisionModel.loadAsync() {
 # overwrite the original model
 model.tracker = foo
 model = model
}
```
By default, an empty model will simply return the first variant.  If you would like Improve to explore different variants during the initial bootstrap phase, you may simply shuffle the variants before passing them to the model and a random one will be chosen.


## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in a variant or givens so that it is not tracked and persisted in your Improve Gym analytics records.

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
