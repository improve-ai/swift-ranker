//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//
import ImproveAICore

public struct Decision<T> {
    internal var decision: IMPDecision
    
    internal var variants: [T]?
    
    internal init(_ decision: IMPDecision, _ variants: [T]?=nil) {
        self.decision = decision
        self.variants = variants
    }
    
    public func get() throws -> T {
        if let variants = self.variants {
            let encodedVariant = self.decision.get()
            let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
            return variants[index]
        } else {
            return self.decision.get() as! T
        }
    }
    
    public func peek() throws -> Any {
        if let variants = self.variants {
            let encodedVariant = self.decision.peek()
            let index = (self.decision.variants as NSArray).indexOfObjectIdentical(to: encodedVariant)
            return variants[index]
        } else {
            return self.decision.get()
        }
    }
    
    public func addReward(_ reward: Double) {
        self.decision.addReward(reward)
    }
}
