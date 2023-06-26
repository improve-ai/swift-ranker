//
//  Rewardable.swift
//  
//
//  Created by Justin on 6/25/23.
//
import Foundation

/**
 Items that conform to `Rewardable` can be used with the `RewardTracker.track()` method. The `RewardTracker` will associate a `rewardId` with the `Rewardable` item and store a reference to itself in the item's `rewardTracker` property.

 This design allows for later rewarding of the `Rewardable` item through its `addReward(_:)` method. Rewards can be added only if the item was previously tracked by a `RewardTracker`.

 Properties:
 - `rewardId`: A `String` that identifies the reward, which gets set when the item is tracked. It can be `nil` if the item hasn't been tracked yet.
 - `rewardTracker`: A reference to the `RewardTracker` that tracked the item. It can be `nil` if the item hasn't been tracked yet.

 */
public protocol Rewardable: AnyObject {
    var rewardId: String? { get set }
    var rewardTracker: RewardTracker? { get set }
    
    /**
    Adds a reward for the `Rewardable` item. This method should be called only if the item was previously tracked by a `RewardTracker`.

    If called on an untracked item, it will print an error and not add the reward.

    - Parameter reward: A `Double` representing the value of the reward to be added.
    */
    func addReward(_ reward: Double)
}

extension Rewardable {
    public func addReward(_ reward: Double) {
        guard let rewardId = self.rewardId else {
            print("[ImproveAI] Error: rewardId is nil.")
            return
        }
        
        guard let rewardTracker = self.rewardTracker else {
            print("[ImproveAI] Error: rewardTracker is nil.")
            return
        }
        
        rewardTracker.addReward(reward, rewardId: rewardId)
    }
}
