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
    
    public func get() -> T {
        let encodedVariant = self.decision.get()
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    public func ranked() -> [T] {
        let rankedVariants = self.decision.ranked()
        return rankedVariants.map({
            (self.decision.variants as NSArray).indexOfObjectIdentical(to: $0)
        }).map({ variants[$0] })
    }
    
    public func track() -> String {
        return self.decision.track()
    }
    
    public func addReward(_ reward: Double) {
        self.decision.addReward(reward)
    }
}
