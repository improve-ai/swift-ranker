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

greeting = decisionModel.given({“language”: “cowboy”}).chooseFrom([“Hello World”, “Howdy World”, “Yo World”]).get()
```

*greeting* should result in *Howdy World* assuming that performs best when *language* is *cowboy*.

### Numbers Too

What discount should we offer?

```swift

discount = try DecisionModel.load(modelUrl).chooseFrom([0.1, 0.2, 0.3]).get()

```

### Complex Objects

```swift
themeVariants = [ { "textColor": "#000000", "backgroundColor": "#ffffff" },
                  { "textColor": "#F0F0F0", "backgroundColor": "#aaaaaa" } ]
                            
theme = themeModel.chooseFrom(themeVariants).get()

```

Improve learns to use the attributes of each key and value in a complex variant to make the optimal decision.
Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, nulls, and booleans.

## Models

Each DecisionModel contains the AI optimized decision logic, which is analogous to a large number of *if/then* statements.  A seperate model is used for each type of decision.

### Synchronous Model Loading

```swift

product = try DecisionModel.load(modelUrl).chooseFrom(["clutch", "dress", "jacket"]).get()

```

Models can be loaded from the app bundle or from https URLs.

### Asynchronous Model Loading

Asynchronous model loading allows decisions to be made at any point, even before the model is loaded.  If the model isn't yet loaded or fails to load, it will simply return the first variant as the decision.

```swift
tracker = new DecisionTracker(trackUrl)
model = new DecisionModel("greetings") 
model.tracker = tracker
model.loadAsync(modelUrl) { result, error in
    if (error)
        NSLog("Error loading model: %@", error)
    } else {
        // the model is ready to go
    }
}
...
// other threads can make decisions at any point, simply returning the first variant if the model isn't loaded
```

## Tracking & Training Models

The magic of Improve AI is it's learning process, where models continuously improve by training on past decisions. To accomplish this, decisions and events are tracked with the Improve AI Gym.

### Tracking Decisions

Both decisions and events are tracked by the DecisionTracker class.  A single DecisionTracker instance can be shared by multiple models.

```swift
tracker = new DecisionTracker(trackUrl)

product = try DecisionModel.load(modelUrl).setTracker(tracker).chooseFrom(["clutch", "dress", "jacket"]).get()
```

The decision is lazily evaluated and automatically tracked upon calling *get()*.

### Tracking Events

Events are the mechanism by which decisions are rewarded or penalized.

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
