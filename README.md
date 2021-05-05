# Improve AI for iOS/MacOS

## Fast AI Decisions for Swift and Objective C
 
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

*greeting* should result in *Howdy World* assuming it performs best when *language* is *cowboy*.

### Numbers Too

What discount should we offer?

```swift

discount = try DecisionModel.load(modelUrl).chooseFrom([0.1, 0.2, 0.3]).get()

```

### Booleans

Dynamically enable feature flags for best performance...

```
featureFlag = decisionModel.given(deviceAttributes).chooseFrom([true, false]).get()
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

A DecisionModel contains the AI optimized decision logic, analogous to a large number of *if/then* statements. Models are thread-safe and a single model can be used for multiple decisions of the same type.

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

The magic of Improve AI is it's learning process, whereby models continuously improve by training on past decisions. To accomplish this, decisions and events are tracked to your deployment of the Improve AI Gym.

### Tracking Decisions

Set a *DecisionTracker* on the *DecisionModel* to automatically track decisions and enable learning.  A single *DecisionTracker* instance can be shared by multiple models.

```swift
tracker = new DecisionTracker(trackUrl) // trackUrl is obtained from your Gym configuration

fontSize = try DecisionModel.load(modelUrl).setTracker(tracker).chooseFrom([12, 16, 20]).get()
```

The decision is lazily evaluated and then automatically tracked as being causal upon calling *get()*.

For this reason, wait to call *get()* until the decision will actually be used.

### Tracking Events

Events are the mechanism by which decisions are rewarded or penalized.  In most cases these will mirror the normal analytics events that your app tracks and can be integrated with any event tracking singletons in your app.

```swift
tracker.track(event: "Purchased", { properties: "product_id": 8, "value": 19.99 })
```

Like most analytics packages, *track* takes an *event* name and an optional *properties* dictionary.  The only property with special significance is *value*, which indicates a reward value for decisions that lead to that event.  If *value* is ommitted then the default reward value is *0.001*.

By default, each decision is rewarded the total value of all events that occur within 48 hours of the decision.

Assuming a typical app where user retention and engagement are valuable, we recommend tracking all of your analytics events with the *DecisionTracker*.  You can customize the rewards assignment logic later in the Improve AI Gym.

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
