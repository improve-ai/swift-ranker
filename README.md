# Rank, Score & Optimize Swift Data Structures

Improve AI is a machine learning platform for quickly implementing app optimization, personalization, and recommendations for [iOS](https://improve.ai/ios-sdk/), [Android](https://improve.ai/android-sdk/), and [Python](https://improve.ai/python-sdk/).

The SDKs provide simple APIs for AI [decisions](https://improve.ai/decisions/), [ranking](https://improve.ai/ranking/), and [scoring](https://improve.ai/scoring/), that execute immediately, on-device, with zero network latency. Items and their rewards are with the [Improve AI Tracker / Trainer](https://github.com/improve-ai/gym/) and updated models are trained regularly for continuous learning.

## Installation

In Xcode:

* File -> Add Packages...
* In 'Search or Enter Package URL' paste <https://github.com/improve-ai/swift-ranker.git>

## Instructions for ChatGPT

Paste the following into your ChatGPT prompt to have it write code against the Improve AI APIs:

```
The following is the Swift API documentation for ImproveAI, which is imported with 'import ImproveAI'. Respond with 'Improve AI documentation imported':

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
     Rank the list of items from best to worst (highest to lowest scoring)
     
     - Parameters:
        - items: The list of items to rank.
        - context: Extra JSON encodable context info that will be used with each of the item to get its score.
     - Returns: An array of ranked items, sorted by their scores in descending order.
    */
    public func rank<T, U>(_ items: [T], context: U? = nil) -> [T] where T: Encodable, U: Encodable
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
     public func score<T, U>(_ items: [T], context: U? = nil) throws -> [Double] where T: Encodable, U: Encodable
}

**
 Tracks items and rewards for training updated scoring models. When an item becomes causal, pass it to the `track()` function, which will return a `rewardId`. Explicitly use the `rewardId` to track future rewards associated with that item. Items can also
 implement the Rewardable protocol to automatically manage rewardIds and allow item.addReward(reward) to be called later.
 */
public struct RewardTracker {
    
    /**
    Initializes a new instance of `RewardTracker`.
    
    - Parameters:
      - modelName: The model's name, such as "songs" or "discounts".
      - trackUrl: The tracking endpoint URL to which all tracked data will be sent.
      - trackApiKey: The tracking endpoint API key (if applicable); Can be nil.
    */
    public init(modelName: String, trackUrl: URL, trackApiKey: String? = nil) 
    
    /**
    Tracks the item selected from candidates and a random sample from the remaining items.

    - Parameters:
      - item: The item that is interacted with. If item conforms to Rewardable the `rewardId` and this `RewardTracker` will be set on it so that `item.addReward(reward)` can be called later.
      - from: The collection of candidates from which the item was chosen. One will be sampled and tracked for propensity scoring/model balancing
      - context: Extra context information that was used with each of the item to get its score.
    - Returns: `rewardId` of this track request.
    */
    public func track<T : Equatable>(item: T?, from candidates: [T?], context: Any? = nil) -> String
    
    /**
    Tracks the item selected and a specific sample candidate.

    - Parameters:
      - item: The item that is interacted with. If item conforms to Rewardable the `rewardId` and this `RewardTracker` will be set on it so that `item.addReward(reward)` can be called later.
      - sample: A random sample from the candidates.
      - numCandidates: The total number of candidates, including the selected item.
      - context: Extra context information that was used with each of the item to get its score.
    - Returns: `rewardId` of this track request.
    */
    public func track(item: Any?, sample: Any?, numCandidates: Int, context: Any? = nil) -> String
    
    /**
    Adds a reward for the provided `rewardId`.

    - Parameters:
      - reward: The reward to add. Must not be NaN or Infinite.
      - rewardId: The id that was returned from the `track()` methods. If nil, it will use the cached `rewardId` for this modelName, if any.
    */
    public func addReward(_ reward: Double, rewardId: String)
}

/**
 Items that conform to `Rewardable` can be used with the `RewardTracker.track()` method. The `RewardTracker` will associate a `rewardId` with the `Rewardable` item and store a reference to itself in the item's `rewardTracker` property.

 This design allows for later rewarding of the `Rewardable` item through its `addReward(_:)` method. Rewards can be added only if the item was previously tracked by a `RewardTracker`.

 Properties:
 - `rewardId`: A `String` that identifies the reward, which gets set when the item is tracked. It can be `nil` if the item hasn't been tracked yet.
 - `rewardTracker`: A reference to the `RewardTracker` that tracked the item. It can be `nil` if the item hasn't been tracked yet.
 */
public protocol Rewardable {
    var rewardId: String? { get set }
    var rewardTracker: RewardTracker? { get set }
    
    /**
    Adds a reward for the `Rewardable` item. This method should be called only if the item was previously tracked by a `RewardTracker`.

    If called on an untracked item, it will print an error and not add the reward.

    - Parameter reward: A `Double` representing the value of the reward to be added.
    */
    mutating func addReward(_ reward: Double)
}

```

## Usage

Create a list of JSON encodable items and simply call *Ranker.rank(items)*.

For instance, in an bedtime story app, you may have a list of *Story* objects:

```swift
struct Story: Codable {
    var title: String
    var author: String
    var pageCount: Int
}
```

To obtain a ranked list of stories, use just one line of code:

```swift
let rankedStories = try Ranker(modelUrl: modelUrl).rank(stories)
```

## Reward Assignment

Easily train your rankers using [reinforcement learning](https://improve.ai/reinforcement-learning/).

First, track when an item is used:

```swift
let tracker = RewardTracker(modelName: "stories", trackUrl: trackUrl)
let rewardId = tracker.track(story, from: rankedStories)
```

Later, if a positive outcome occurs, provide a reward:

```swift
if (purchased) {
    tracker.addReward(profit, rewardId: rewardId)
}
```

Reinforcement learning uses positive rewards for favorable outcomes (a "carrot") and negative rewards for undesirable outcomes (a "stick"). By assigning rewards based on business metrics, such as revenue or conversions, the system optimizes these metrics over time.

## Contextual Ranking & Scoring

Improve AI turns XGBoost into a *contextual multi-armed bandit*, meaning that context is considered when making ranking or scoring decisions.

Often, the choice of the best variant depends on the context that the decision is made within. Let's take the example of greetings for different times of the day:

```Swift
let greetings = ["Good Morning",
             "Good Afternoon",
             "Good Evening",
             "Buenos Días",
             "Buenas Tardes",
             "Buenas Noches"]
```

*rank()* also considers the *context* of each decision. The context can be any JSON-encodable data structure.

```Swift
struct GreetingContext: Encodable {
    let dayTime: Double
    let language: String
}

let ranked = try ranker.rank(greetings, context: GreetingContext(dayTime: 12.0, language: "en"))

let greeting = ranked[0]
```

Trained with appropriate rewards, Improve AI would learn from scratch which greeting is best for each time of day and language.

## Logging

Debug logging is enabled by default for builds with DEBUG set to TRUE. To disable logging, set IMPROVE_AI_DEBUG to FALSE

## Resources

- [Quick Start Guide](https://improve.ai/quick-start/)
- [Tracker / Trainer](https://github.com/improve-ai/tracker-trainer/)
- [Reinforcement Learning](https://improve.ai/reinforcement-learning/)

## Help Improve Our World

The mission of Improve AI is to make our corner of the world a little bit better each day. When each of us improve our corner of the world, the whole world becomes better. If your product or work does not make the world better, do not use Improve AI. Otherwise, welcome, I hope you find value in my labor of love. 

-- Justin Chapweske
