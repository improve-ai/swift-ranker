# Improve AI for iOS

## AI Decisions in Swift and Objective C

Lift revenue, performance, user retention, or any other metric with fast AI decisions. It's like an AI *if/then* statement. 

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

greeting = decisionModel.given({“language”: “cowboy”}).which(“Hello World”, “Howdy World”, “Yo World”)
```

*greeting* should result in *Howdy World* assuming it performs best when *language* is *cowboy*.

### Numbers Too

What discount should we offer?

```swift

discount = discountModel.which(0.1, 0.2, 0.3)

```

### Booleans

Dynamically enable feature flags for best performance...

```
featureFlag = decisionModel.given(deviceAttributes).which(true, false)
```

### Complex Objects

```swift
themeVariants = [ { "textColor": "#000000", "backgroundColor": "#ffffff" },
                  { "textColor": "#F0F0F0", "backgroundColor": "#aaaaaa" } ]
                            
theme = themeModel.which(themeVariants)

```
When a single Array argument is passed to which, it is treated as a list of variants.

Improve learns to use the attributes of each key and value in a complex variant to make the optimal decision.

Variants can be any JSON encodeable data structure of arbitrary complexity, including nested dictionaries, arrays, strings, numbers, nulls, and booleans.

## Decision Models

A *Decision Model* contains the AI decision logic, analogous to a large number of *if/then* statements.  Decision models are continuously trained by the Improve AI Gym based on previous decisions, so they automatically improve over time.

Models are thread-safe and a single model can be used for multiple decisions.

### Synchronous Model Loading

```swift

product = try DecisionModel("products").load(modelUrl).which("clutch", "dress", "jacket")

```

Models can be loaded from the app bundle or from https URLs.

### Asynchronous Model Loading

Asynchronous model loading allows decisions to be made at any point, even before the model is loaded.  If the model isn't yet loaded or fails to load, the first variant will be returned as the decision.

```swift
model = DecisionModel("greetings") 
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
greeting = model.which(“Hello World”, “Howdy World”, “Yo World”)
```

## Tracking & Training Models

The magic of Improve AI is it's learning process, whereby models continuously improve by training on past decisions. To accomplish this, decisions and events are tracked to your deployment of the Improve AI Gym.

### Tracking Decisions

Set a *DecisionTracker* on the *DecisionModel* to automatically track decisions and enable learning.  A single *DecisionTracker* instance can be shared by multiple models.

```swift
DecisionModel.defaultTrackURL = trackURL // trackUrl is obtained from your Gym configuration

// When a new DecisionModel instance is created, it's trackURL is set to DecisionModel.defaultTrackURL
fontSize = try DecisionModel("fontSizes").load(modelUrl).which(12, 16, 20)
```

The decision is lazily evaluated and then automatically tracked as being causal upon calling *get()*.

For this reason, wait to call *get()* until the decision will actually be used.

### Tracking Rewards

Events are the mechanism by which decisions are rewarded or penalized.  In most cases these will mirror the normal analytics events that your app tracks and can be integrated with any event tracking singletons in your app.

```swift
decisionModel.addReward(19.99)
```

## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in variants or givens so that it is never tracked, persisted, or used as training data.

## Improve Our World

The mission of Improve AI is to make our corner of the world better. When each of us improve our corner of the world, the whole world becomes better. If your product or work does not make the world better, do not use Improve AI. Otherwise, welcome, I hope you find value in my labor of love. - Justin Chapweske

## License

Improve AI is copyright Mind Blown Apps, LLC. All rights reserved.  May not be used without a license.
