//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//

import ImproveAICore
import AnyCodable

public struct DecisionContext {
    internal var decisionContext: IMPDecisionContext
    
    internal init(decisionContext: IMPDecisionContext) {
        self.decisionContext = decisionContext
    }
    
    public func score<T : Encodable>(_ variants: [T]) throws -> [Double] {
        let encodedVariants = try PListEncoder().encode(variants) as! [Any]
        return self.decisionContext.score(encodedVariants).map{ $0.doubleValue }
    }
    
    public func chooseFrom<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        let encodedVariants = try PListEncoder().encode(variants) as! [Any]
        return Decision(self.decisionContext.chooseFrom(encodedVariants), variants)
    }
    
    public func chooseFrom<T : Encodable>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
        let encodedVariants = try PListEncoder().encode(variants) as! [Any]
        return Decision(self.decisionContext.chooseFrom(encodedVariants, scores.map{NSNumber(value: $0)}), variants)
    }

    public func chooseFirst<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        let encodedVariants = try PListEncoder().encode(variants) as! [Any]
        return Decision(self.decisionContext.chooseFirst(encodedVariants), variants)
    }
    
    public func first<T : Encodable>(_ variants: T...) throws -> T {
        return try self.chooseFirst(variants).get()
    }

    public func chooseRandom<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        let encodedVariants = try PListEncoder().encode(variants) as! [Any]
        return Decision(self.decisionContext.chooseRandom(encodedVariants), variants)
    }
    
    public func random<T : Encodable>(_ variants: T...) throws -> T {
        return try self.chooseRandom(variants).get()
    }

    public func which<T : Encodable>(_ variants: T...) throws -> T {
        if variants.count <= 0 {
            throw IMPError.emptyVariants
        }
        return try chooseFrom(variants).get()
    }
    
    public func which<T: Encodable>(_ variants: [T]) throws -> T {
        if variants.count <= 0 {
            throw IMPError.emptyVariants
        }
        return try chooseFrom(variants).get()
    }
    
    public func which(_ variants: [String: Any]) throws -> Any {
        return try chooseMultiVariate(variants).get()
    }
    
    public func chooseMultiVariate(_ variants: [String : Any]) throws -> Decision<Any> {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        var categories: [[AnyCodable]] = []
        var keys: [String] = []
        for (k, v) in variants {
            if let x = v as? [Any] {
                categories.append(x.map{AnyCodable($0)})
            } else {
                categories.append([AnyCodable(v)])
            }
            keys.append(k)
        }

        var combinations: [[String:AnyCodable]] = []
        for i in 0..<categories.count {
            let category = categories[i]
            var newCombinations:[[String:AnyCodable]] = []
            for m in 0..<category.count {
                if combinations.count == 0 {
                    newCombinations.append([keys[i]:category[m]])
                } else {
                    for n in 0..<combinations.count {
                        var newVariant = combinations[n]
                        newVariant[keys[i]] = category[m]
                        newCombinations.append(newVariant)
                    }
                }
            }
            combinations = newCombinations
        }
        
        let encodedVariants = try PListEncoder().encode(combinations) as! [Any]
        
        return Decision(self.decisionContext.chooseFrom(encodedVariants), nil)
    }
}
