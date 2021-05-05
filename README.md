# Improve AI for iOS

## Fast AI Decisions for iOS, Android, and the Cloud
 
[![Version](https://img.shields.io/cocoapods/v/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![License](https://img.shields.io/cocoapods/l/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)
[![Platform](https://img.shields.io/cocoapods/p/Improve.svg?style=flat)](http://cocoapods.org/pods/Improve)

It's like an AI *if/then* statement. Quickly make decisions that maximize revenue, performance, user retention, or any other metric.

## Installation

Improve is available through [CocoaPods](http://cocoapods.org). To install, add the following line to your Podfile:

```ruby
pod "Improve"
```

### Hello World (for Cowboys)!

What is the best greeting?

```swift

greeting = DecisionModel.load(modelUrl).given({“language”: “cowboy”}).chooseFrom([“Hello World”, “Howdy World”, “Hi World”]).get()
```

*greeting* should be *"Howdy World"* assuming that performs best when ```language == "cowboy"```.

### Numbers Too

What discount should we offer today?

```swift

discount = DecisionModel.load(modelUrl).chooseFrom([0.1, 0.2, 0.3]).get()

```

### Complex Objects

```swift
themeVariants = [ { "textColor": "#000000", "backgroundColor": "#ffffff" },
                  { "textColor": "#F0F0F0", "backgroundColor": "#aaaaaa" } ]
                            
theme = themeModel.chooseFrom(themeVariants).get()

```

Improve learns to use the attributes of each key and value in a complex variant to make the optimal decision.
Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, null values, and booleans.

## Training

TODO

## Bootstrapping a New Model

TODO
```
model = new DecisionModel("themes") # create an empty model
model.tracker = foo

DecisionModel.loadAsync() {
 # replace the empty model
 model.tracker = foo
 model = model
}
```
By default, an empty model will simply return the first variant.  If you would like Improve to explore different variants during the initial bootstrap phase, you may simply shuffle the variants before passing them to the model and a random one will be chosen.

 ## Ranking and Scoring

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

## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in a variant or givens so that it is not tracked and persisted in your Improve Gym analytics records.

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
