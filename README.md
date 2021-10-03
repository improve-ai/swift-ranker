# Improve AI for iOS

## Fast AI Decisions for Swift and Objective C

It's like an AI *if/then* statement. Quickly make decisions that configure your app to maximize revenue, performance, user retention, or any other metric.

## Installation

Improve is available through Swift Package Manager. Add the dependency by adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/improve-ai/ios-sdk.git", .upToNextMajor(from: "6.0.0"))
]
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

discount = discountModel.chooseFrom([0.1, 0.2, 0.3]).get()

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

## Decision Models

A *Decision Model* contains the AI decision logic, analogous to a large number of *if/then* statements.  Decision models are continuously trained by the Improve AI Gym based on previous decisions, so they automatically improve over time.

Models are thread-safe and a single model can be used for multiple decisions.

### Synchronous Model Loading

```swift

product = try DecisionModel.load(modelUrl).chooseFrom(["clutch", "dress", "jacket"]).get()

```

Models can be loaded from the app bundle or from https URLs.

### Asynchronous Model Loading

Asynchronous model loading allows decisions to be made at any point, even before the model is loaded.  If the model isn't yet loaded or fails to load, the first variant will be returned as the decision.

```swift
tracker = new DecisionTracker(trackUrl)
model = new DecisionModel("greetings") 
model.tracker = tracker
model.loadAsync(modelUrl) { loadedModel, error in
    // loadedModel is the same reference as model but is made available to allow async chaining
    if (error)
        NSLog("Error loading model: %@", error)
    } else {
        // the model is ready to go
    }
}

// It is very unlikely that the model will be loaded by the time this is called, 
// so "Hello World" would be returned and tracked as the decision
greeting = model.chooseFrom([“Hello World”, “Howdy World”, “Yo World”]).get()
```

## Tracking & Training Models

The magic of Improve AI is it's learning process, whereby models continuously improve by training on past decisions. To accomplish this, decisions and events are tracked to your deployment of the Improve AI Gym.

### Tracking Decisions

Set a *DecisionTracker* on the *DecisionModel* to automatically track decisions and enable learning.  A single *DecisionTracker* instance can be shared by multiple models.

```swift
tracker = new DecisionTracker(trackUrl) // trackUrl is obtained from your Gym configuration

fontSize = try DecisionModel.load(modelUrl).track(tracker).chooseFrom([12, 16, 20]).get()
```

The decision is lazily evaluated and then automatically tracked as being causal upon calling *get()*.

For this reason, wait to call *get()* until the decision will actually be used.

### Tracking Events

Events are the mechanism by which decisions are rewarded or penalized.  In most cases these will mirror the normal analytics events that your app tracks and can be integrated with any event tracking singletons in your app.

```swift
tracker.track(event: "Purchased", { properties: "product_id": 8, "value": 19.99 })
```

Like most analytics packages, *track* takes an *event* name and an optional *properties* dictionary.  The only property with special significance is *value*, which indicates a reward value for decisions prior to that event.  

If *value* is ommitted then the default reward value of an event is *0.001*.

By default, each decision is rewarded the total value of all events that occur within 48 hours of the decision.

Assuming a typical app where user retention and engagement are valuable, we recommend tracking all of your analytics events with the *DecisionTracker*.  You can customize the rewards assignment logic later in the Improve AI Gym.

## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in variants or givens so that it is never tracked, persisted, or used as training data.

## An Ask

Thank you so much for enjoying my labor of love. Please only use it to create things that are good, true, and beautiful. - Justin Chapweske

## License

Improve AI is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
