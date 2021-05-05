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

greeting = greetingsModel.given({“language”: “cowboy”}).chooseFrom([“Hello World”, “Howdy World”, “Yo World”]).get()
```

*greeting* should result in *Howdy World* assuming that performs best when *language* is *cowboy*.

### Numbers Too

What discount should we offer?

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
Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, nulls, and booleans.

## Training

TODO

### Dummy Models

Sometimes you'll need to be able to make immediate decisions without waiting for the model to load. In this case, use a dummy model.

```
tracker = new DecisionTracker(trackUrl)
model = new DecisionModel("discounts") # create a dummy model with the same name configured in the gym
model.tracker = tracker

DecisionModel.loadAsync() {
 # replace the dummy model
 model = loadedModel
 model.tracker = tracker
}
```
By default, a dummy model will simply return the first variant.  It will act as a placeholder until the actual model is loaded and if it is used, the decisions will still be tracked and learning will continue.

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
  
It is strongly recommended to never include Personally Identifiable Information (PII) in variants or givens so that it is not tracked and persisted in your Improve Gym analytics records.

## License

Improve.ai is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
