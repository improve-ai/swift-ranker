# Rank, Score & Optimize Swift Data Structures

Improve AI is a machine learning platform for quickly implementing app optimization, personalization, and recommendations for [iOS](https://improve.ai/ios-sdk/), [Android](https://improve.ai/android-sdk/), and [Python](https://improve.ai/python-sdk/).

The SDKs provide simple APIs for AI [decisions](https://improve.ai/decisions/), [ranking](https://improve.ai/ranking/), [scoring](https://improve.ai/scoring/), and [multivariate optimization](https://improve.ai/multivariate-optimization/) that execute immediately, on-device, with zero network latency. Decisions and rewards are tracked in the cloud with the [Improve AI Gym](https://github.com/improve-ai/gym/) and updated models are trained regularly on AWS SageMaker.

## Installation

In Xcode:

* File -> Add Packages...
* In 'Search or Enter Package URL' paste <https://github.com/improve-ai/swift-ranker.git>


## Instructions for ChatGPT

Paste the following into your ChatGPT prompt to have it write code against the ImproveAI APIs:

```
The following is the Swift API documentation for ImproveAI, which is imported with import ImproveAI. When generating examples from this documentation,
include details on item tracking and reward assignment. Simply respond with 'ImproveAI documentation imported':

/**
 A utility for ranking items based on their scores. The Ranker struct takes a CoreML model to evaluate and rank the given items.
 */
public struct Ranker {
    
    /**
     Create a Ranker instance with a CoreML model.
     
     - Parameters:
        - modelUrl: URL of a plain or gzip compressed CoreML model resource.
     
     - Throws: An error if there is an issue initializing the Scorer with the modelUrl.
    */
    init(modelUrl: URL) throws
    
    /**
     Rank the list of items by their scores.
     
     - Parameters:
        - items: The list of items to rank.
        - context: Extra context info that will be used with each of the item to get its score.
     
     - Returns: An array of ranked items, sorted by their scores in descending order.
     
     - Throws: An error if there is an issue ranking the items.
    */
    public func rank<T>(items: [T], context: Any? = nil) throws -> [T] 
}

/**
 Scores items with optional context using a CoreML model.
 */
public struct Scorer {

    /**
     Initialize a Scorer instance.
     
     - Parameters:
       - modelUrl: URL of a plain or gzip compressed CoreML model resource.
     - Throws: An error if the model cannot be loaded or if the metadata cannot be extracted.
     */
    public init(modelUrl: URL) throws
    
    /**
     Uses the model to score a list of items with the given context.
     
     - Parameters:
      - items: The list of items to score.
      - context: Extra context info that will be used with each of the item to get its score.
     - Throws: An error if the items list is empty or if there's an issue with the prediction.
     - Returns: An array of `Double` values representing the scores of the items.
     */
    public func score(items: [Any?], context: Any? = nil) throws -> [Double]
}

/**
 Tracks items and rewards for training updated scoring models. When an item becomes causal, pass it to the track() function, which will return a rewardId. Use the rewardId to track future rewards associated with that item.
 */
public struct RewardTracker {
    
    /// Create an instance.
    ///
    /// - Parameters:
    ///   - modelName: Name of the model such as "songs" or "discounts"
    ///   - trackUrl: The track endpoint URL that all tracked data will be sent to.
    ///   - trackApiKey: track endpoint API key (if applicable); Can be nil.
    public init(modelName: String, trackUrl: URL, trackApiKey: String? = nil) throws
    
    /// Tracks the item selected from candidates and a random sample from the remaining items.
    ///
    /// - Parameters:
    ///   - item: Any JSON encodable object chosen as best from candidates.
    ///   - candidates: Collection of items from which best is chosen.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: rewardId of this track request.
    public func track<T : Equatable>(item: T?, candidates: [T?], context: Any? = nil) throws -> String
    
    /// Tracks the item selected and a specific sample.
    ///
    /// - Parameters:
    ///   - item: The selected item.
    ///   - sample: A specific sample from the candidates.
    ///   - numCandidates: Total number of candidates, including the selected item.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: rewardId of this track equest
    public func track(item: Any?, sample: Any?, numCandidates: Int, context: Any? = nil) throws -> String
    
    /// Add reward for the provided rewardId
    ///
    /// - Parameters:
    ///   - reward: The reward to add. Must not be NaN or Infinite.
    ///   - rewardId: The id that was returned from the track() methods.
    public func addReward(reward: Double, rewardId: String) throws {

```
## Initialization

```swift
import ImproveAI
```

```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    // track and model urls are obtained from your Improve AI Gym configuration
    trackUrl = 'https://xxxx.lambda-url.us-east-1.on.aws/'
    modelUrl = 'https://xxxx.s3.amazonaws.com/models/latest/greetings.mlmodel.gz'

    DecisionModel.defaultTrackURL = trackURL

    DecisionModel["greetings"].loadAsync(modelUrl)

    return true
}
```

## Usage

The heart of Improve AI is the *which()* statement. *which()* is like an AI *if/then* statement.

```swift
greeting = DecisionModel["greetings"].which("Hello", "Howdy", "Hola")
```

*which()* takes a list of *variants* and returns the best - the "best" being the variant that provides the highest expected reward given the current conditions.

Decision models are easily trained with [reinforcement learning](https://improve.ai/reinforcement-learning/):

```swift
if (likeTapped) {
    DecisionModel["greetings"].addReward(1.0)
}
```

With reinforcement learning, positive rewards are assigned for positive outcomes (a "carrot") and negative rewards are assigned for undesirable outcomes (a "stick").

*which()* automatically tracks it's decision with the [Improve AI Gym](https://github.com/improve-ai/gym/). Rewards are credited to the most recent tracked decision for each model, including from a previous app session.

## Contextual Decisions

Unlike A/B testing or feature flags, Improve AI uses *context* to make the best decision for each user. On iOS, the following context is automatically included:

- *$country* - two letter country code
- *$lang* - two letter language code
- *$tz* - numeric GMT offset
- *$carrier* - cellular network
- *$device* - string portion of device model
- *$devicev* - device version
- *$os* - string portion of OS name
- *$osv* - OS version
- *$pixels* - screen width x screen height
- *$app* - app name
- *$appv* - app version
- *$sdkv* - Improve AI SDK version
- *$weekday* - (ISO 8601, monday==1.0, sunday==7.0) plus fractional part of day
- *$time* - fractional day since midnight
- *$runtime* - fractional days since session start
- *$day* - fractional days since born
- *$d* - the number of decisions for this model
- *$r* - total rewards for this model
- *$r/d* - total rewards/decisions
- *$d/day* - decisions/$day

Using the context, on a Spanish speaker's device we expect our *greetings* model to learn to choose *Hola*.

Custom context can also be provided via *given()*:

```swift
greeting = DecisionModel["greetings"].given(["language": "cowboy"])
                                     .which("Hello", "Howdy", "Hola")
```

Given the language is *cowboy*, the variant with the highest expected reward should be *Howdy* and the model would learn to make that choice.

## Ranking

[Ranking](https://improve.ai/ranking/) is a fundamental task in recommender systems, search engines, and social media feeds. Fast ranking can be performed on-device in a single line of code:

```swift
rankedWines = sommelierModel.given(entree).rank(wines)
```

**Note**: Decisions are not tracked when calling *rank()*. *which()* or *decide()* must be used to train models for ranking.

## Scoring

[Scoring](https://improve.ai/scoring/) makes it easy to turn any database table into a recommendation engine.

Simply add a *score* column to the database and update the score for each row.

```swift
scores = conversionRateModel.score(rows)
```

At query time, sort the query results descending by the *score* column and the first results will be the top recommendations. This works particularly well with local databases on mobile devices where the scores can be personalized to each individual user.

*score()* is also useful for crafting custom optimization algorithms or providing supplemental metrics in a multi-stage recommendation system.

**Note**: Decisions are not tracked when calling *score()*. *which()*, *decide()*, or *optimize()* must be used to train models for scoring.

## Multivariate Optimization

[Multivariate optimization](https://improve.ai/multivariate-optimization/) is the joint optimization of multiple variables simultaneously. This is often useful for app configuration and performance tuning.

```swift
config = configModel.optimize({"bufferSize": [1024, 2048, 4096, 8192],
                               "videoBitrate": [256000, 384000, 512000]})
```

This example decides multiple variables simultaneously.  Notice that instead of a single list of variants, a dictionary mapping keys to lists of variants is provided. This multi-variate mode jointly optimizes all variables for the highest expected reward.  

*optimize()* automatically tracks it's decision with the [Improve AI Gym](https://github.com/improve-ai/gym/). Rewards are credited to the most recent decision made by the model, including from a previous app session.

## Variant Types

Variants and givens can be any object conforming to the [*Codable*](https://developer.apple.com/documentation/swift/codable) interface. This includes *Int*, *Double*, *Bool*, *String*, *Dictionary*, *Array*, *nil*, as well as any custom *Codable* objects. Object properties and nested items within collections are automatically encoded as machine learning features to assist in the decision making process.

The following are all valid:

```swift
greeting = greetingsModel.which("Hello", "Howdy", "Hola")

discount = discountModel.which(0.1, 0.2, 0.3)

enabled = featureFlagModel.which(true, false)

item = filterModel.which(item, nil)

themes = [[ "font": "Helvetica", "size": 12, "color": "#000000"  ],
          [ "font": "Comic Sans", "size": 16, "color": "#F0F0F0" ]]

theme = themeModel.which(themes)
```

To use a custom class or struct as a variant, declare it as implementing *Codable*:

```swift
struct Theme: Codable {
    var font: String
    var size: Int
    var color: String
}

theme = themeModel.which(themes)
```

## Privacy
  
It is strongly recommended to never include Personally Identifiable Information (PII) in variants or givens so that it is never tracked, persisted, or used as training data.

## Resources

- [Quick Start Guide](https://improve.ai/quick-start/)
- [iOS SDK API Docs](https://improve.ai/ios-sdk/)
- [Improve AI Gym](https://github.com/improve-ai/gym/)
- [Improve AI Trainer (FREE)](https://aws.amazon.com/marketplace/pp/prodview-pyqrpf5j6xv6g)
- [Improve AI Trainer (PRO)](https://aws.amazon.com/marketplace/pp/prodview-adchtrf2zyvow)
- [Reinforcement Learning](https://improve.ai/reinforcement-learning/)
- [Decisions](https://improve.ai/multivariate-optimization/)
- [Ranking](https://improve.ai/ranking/)
- [Scoring](https://improve.ai/scoring/)
- [Multivariate optimization](https://improve.ai/multivariate-optimization/)


## Help Improve Our World

The mission of Improve AI is to make our corner of the world a little bit better each day. When each of us improve our corner of the world, the whole world becomes better. If your product or work does not make the world better, do not use Improve AI. Otherwise, welcome, I hope you find value in my labor of love. 

-- Justin Chapweske
