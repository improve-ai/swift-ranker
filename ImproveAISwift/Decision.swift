//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//
import ImproveAICore

public struct Decision<T> {
    internal var decision: IMPDecision
    
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
    
    public func peek() -> T {
        let encodedVariant = self.decision.peek()
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    public func addReward(_ reward: Double) {
        self.decision.addReward(reward)
    }
}
