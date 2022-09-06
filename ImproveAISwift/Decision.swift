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
    
    internal init(_ decision: IMPDecision, _ variants: [T]) {
        self.decision = decision
        self.variants = variants
    }
    
    public func get(_ trackOnce: Bool = true) -> T {
        let encodedVariant = self.decision.get(trackOnce)
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    public func ranked(_ trackOnce: Bool = true) -> [T] {
        let rankedVariants = self.decision.ranked(trackOnce)
        return rankedVariants.map({
            (self.decision.variants as NSArray).indexOfObjectIdentical(to: $0)
        }).map({ variants[$0] })
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func peek() -> T {
        let encodedVariant = self.decision.peek()
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    public func addReward(_ reward: Double) {
        self.decision.addReward(reward)
    }
}
