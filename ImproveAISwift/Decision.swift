//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//
import ImproveAICore

public struct Decision<T> {
    internal var decision: IMPDecision
    
    /// original variants
    internal var variants: [T]
    
    /// The id that uniquely identifies the decision after it's been tracked. It's nil until the decision
    /// is tracked by calling track().
    public var id: String? {
        return decision.id
    }
    
    /// Additional context info that was used along with each of the variants to score them, including the givens
    /// passed by DecisionModel.given() and givens that was provided by the givensProvider. The givens here
    /// would also be included in tracking.
    public let givens: [String : Any]?
    
    /// The ranked variants.
    public let ranked: [T]
    
    /// The best variant.
    public var best: T {
        return ranked[0]
    }
    
    internal init(_ decision: IMPDecision, _ variants: [T]) {
        self.decision = decision
        self.variants = variants
        self.givens = decision.givens
        let encodedVariants = decision.value(forKey: "variants")
        ranked = decision.ranked.map({
            return (encodedVariants as! NSArray).indexOfObjectIdentical(to: $0)
        }).map({ variants[$0] })
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func peek() -> T {
        let encodedVariant = self.decision.peek()
        
        let encodedVariants = decision.value(forKey: "variants")
        let index = (encodedVariants as! NSArray).indexOfObjectIdentical(to: encodedVariant)
        
        return variants[index]
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func get() -> T {
        let encodedVariant = self.decision.get()
        
        let encodedVariants = decision.value(forKey: "variants")
        let index = (encodedVariants as! NSArray).indexOfObjectIdentical(to: encodedVariant)
        
        return variants[index]
    }
    
    /// Tracks the decision.
    /// - Returns: The id that uniquely identifies the tracked decision.
    public func track() -> String {
        return self.decision.track()
    }
    
    /// Adds rewards that only apply to this specific decision. Before calling this method, make sure that the decision is
    /// already tracked by calling track().
    ///
    /// - Parameter reward: The reward to add. Must not be NaN, or Infinity.
    /// - Throws: `IMPError.invalidArgument` if reward is NaN or infinity.
    /// - Throws: `IMPError.illegalState` if the the decision is not tracked yet.
    public func addReward(_ reward: Double) throws {
        if reward.isNaN || reward.isInfinite {
            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinity.")
        }
        
        if self.id == nil {
            throw IMPError.illegalState(reason: "addReward() can't be called before track().")
        }
        
        self.decision.addReward(reward)
    }
}
