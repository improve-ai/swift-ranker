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
    
    /// The ranked variants.
    public let ranked: [T]
    
    /// The best variant.
    public var best: T {
        return ranked[0]
    }
    
    internal init(_ decision: IMPDecision, _ variants: [T]) {
        self.decision = decision
        self.variants = variants
        ranked = decision.ranked.map({
            (decision.variants as NSArray).indexOfObjectIdentical(to: $0)
        }).map({ variants[$0] })
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func peek() -> T {
        let encodedVariant = self.decision.peek()
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func get() -> T {
        let encodedVariant = self.decision.get()
        let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
        return variants[index]
    }
    
    public func track() -> String {
        return self.decision.track()
    }
    
    public func addReward(_ reward: Double) {
        self.decision.addReward(reward)
    }
}
