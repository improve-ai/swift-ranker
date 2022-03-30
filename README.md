# Improve AI for iOS

Improve AI provides quick on-device AI decisions that get smarter over time. It's like an AI *if/then* statement. Replace guesses in your app's configuration with AI decisions to increase your app's revenue, user retention, or any other metric automatically.

## Installation

* File -> Swift Package Manager -> Add Package Dependency
* Type in https://github.com/improve-ai/ios-sdk.git when choosing package repo.

## Initialization

```swift
import ImproveAI
```

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    DecisionModel.defaultTrackURL = trackURL // trackUrl is obtained from your Improve AI Gym configuration

    DecisionModel.instances["greetings"].loadAsync(greetingsModelUrl) // greetingsModelUrl is a trained model output by the Improve AI Gym

    return true
}
```

## Usage

Improve AI makes quick on-device AI decisions that get smarter over time. 

The heart of Improve AI is the *which* statement. *which* is like an AI if/then statement.
```swift
greeting = DecisionModel.instances["greetings"].which("Hello", "Howdy", "Hola")
```

*which* makes decisions on-device using a *decision model*. Decision models are easily trained by assigning rewards for positive outcomes.

```swift
if (success) {
    DecisionModel.instances["greetings"].addReward(1.0)
}
```

Rewards are credited to the most recent decision made by the model. *which* will make the decision that provides the highest expected reward.  When the rewards are business metrics, such as revenue or user retention, the decisions will optimize to automatically improve those metrics over time.

*That's like A/B testing on steroids.*

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

## Decisions are Contextual

Unlike A/B testing or feature flags, Improve AI uses *context* to make the best decision for each user. On iOS, the following context is automatically included:

- $country - two letter country code
- $lang - two letter language code
- $tz - numeric GMT offset
- $carrier - cellular network
- $device - string portion of device model
- $devicev - device version
- $os - string portion of OS name
- $osv - OS version
- $pixels - screen width x screen height
- $app - app name
- $appv - app version
- $sdkv - Improve AI SDK version
- $weekday - (ISO 8601, monday==1.0, sunday==7.0) plus fractional part of day
- $time - fractional day since midnight
- $runtime - fractional days since session start
- $day - fractional days since born
- $d - the number of decisions for this model
- $r - total rewards for this model
- $r/d - total rewards/decisions
- $d/day - decisions/$day

Using the context, on a Spanish speaker's device we expect our *greetings* model to learn to choose *Hola*.

Custom context can also be provided via *given()*:

```swift
greeting = greetingsModel.given({"language": "cowboy"})
                         .which("Hello", "Howdy", "Hola")
```

Given the language is *cowboy*, the variant with the highest expected reward should be *Howdy* and the model would learn to make that choice.

## Example: Optimizing an Upsell Offer

Improve AI is powerful and flexible.  Variants can be any JSON encodeable data structure including **strings**, **numbers**, **booleans**, **lists**, and **dictionaries**.

For a dungeon crawler game, say the user was purchasing an item using an In App Purchase.  We can use Improve AI to choose an additional product to display as an upsell offer during checkout. With a few lines of code, we can train a model that will learn to optimize the upsell offer given the original product being purchased. 

```swift
product = { "name": "red sword", "price": 4.99 }

upsell = upsellModel.given(product)
                    .which({ "name": "gold", "quantity": 100, "price": 1.99 },
                           { "name": "diamonds", "quantity": 10, "price": 2.99 },
                           { "name": "red scabbard", "price": 0.99 })
```
The product to be purchased is the **red sword**.  Notice that the variants are dictionaries with a mix of string and numeric values.

The rewards in this case might be any additional revenue from the upsell.

```swift
if (upsellPurchased) {
    upsellModel.addReward(upsell.price)
}
```

While it is reasonable to hypothesize that the **red scabbord** might be the best upsell offer to pair with the **red sword**, it is still a guess. Any time a guess is made on the value of a variable, instead use Improve AI to decide.

*Replace guesses with AI decisions.*

## Example: Performance Tuning

In the 2000s I was writing a lot of video streaming code. The initial motivation for Improve AI came out of my frustrations with attempting to tune video streaming clients across heterogenious networks.

I was forced to make guesses on performance sensitive configuration defaults through slow trial and error. My client configuration code maybe looked something like this:

```swift
config = { "bufferSize": 2048,
           "videoBitrate": 384000 }
```

This is the code I wish I could have written:

```swift
config = configModel.which({"bufferSize": [1024, 2048, 4096, 8192],
                            "videoBitrate": [256000, 384000, 512000]})
```
This example decides multiple variables simultaneously.  Notice that instead of a single list of variants, a dictionary mapping keys to lists of variants is provided to *which*. This multi-variate mode jointly optimizes both variables for the highest expected reward.  

The rewards in this case might be negative to penalize any stalls during video playback.
```swift
if (videoStalled) {
    configModel.addReward(-0.001)
}
```
Improve AI frees us from having to overthink our configuration values during development. We simply give it some reasonable variants and let it learn from real world usage.

Look for places where you're relying on guesses or an executive decision and consider instead directly optimizing for the outcomes you desire.

## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in variants or givens so that it is never tracked, persisted, or used as training data.

## Help Improve Our World

The mission of Improve AI is to make our corner of the world a little bit better each day. When each of us improve our corner of the world, the whole world becomes better. If your product or work does not make the world better, do not use Improve AI. Otherwise, welcome, I hope you find value in my labor of love. - Justin Chapweske
