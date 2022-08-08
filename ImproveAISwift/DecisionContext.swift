//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//

import ImproveAICore

public struct DecisionContext {
    internal var decisionContext: IMPDecisionContext
    
    internal init(decisionContext: IMPDecisionContext) {
        self.decisionContext = decisionContext
    }
    
    public func score<T>(_ variants: [T]) throws -> [Double] {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
        return self.decisionContext.score(encodedVariants).map{ $0.doubleValue }
    }
    
    public func chooseFrom<T>(_ variants: [T]) throws -> Decision<T> {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
        return Decision(self.decisionContext.chooseFrom(encodedVariants), variants)
    }
    
    public func chooseFrom<T>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
        return Decision(self.decisionContext.chooseFrom(encodedVariants, scores.map{NSNumber(value: $0)}), variants)
    }

    public func chooseFirst<T>(_ variants: [T]) throws -> Decision<T> {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
        return Decision(self.decisionContext.chooseFirst(encodedVariants), variants)
    }
    
    public func first<T>(_ variants: [T]) throws -> T {
        return try chooseFirst(variants).get()
    }
    
    public func first<T>(_ variants: T...) throws -> T {
        return try chooseFirst(variants).get()
    }
    
    public func first(_ variants: Any...) throws -> Any {
        return try chooseFirst(variants).get()
    }

    public func chooseRandom<T>(_ variants: [T]) throws -> Decision<T> {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
        return Decision(self.decisionContext.chooseRandom(encodedVariants), variants)
    }
    
    public func random<T>(_ variants: [T]) throws -> T {
        return try chooseRandom(variants).get()
    }
    
    public func random<T>(_ variants: T...) throws -> T {
        return try chooseRandom(variants).get()
    }
    
    public func random(_ variants: Any...) throws -> Any {
        return try chooseRandom(variants).get()
    }
    
    public func which(_ variants: Any...) throws -> Any {
        return try which(variants)
    }
    
    public func which<T>(_ variants: T...) throws -> T {
        return try which(variants)
    }
    
    public func which<T>(_ variants: [T]) throws -> T {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        return try chooseFrom(variants).get()
    }
    
    public func chooseMultivariate<T>(_ variants: [String : [T]]) throws -> Decision<[String : T]> {
        var categories: [[AnyEncodable]] = []
        var keys: [String] = []
        for (k, v) in variants {
            if !v.isEmpty {
                categories.append(v.map{ AnyEncodable($0) })
                keys.append(k)
            }
        }
        
        if categories.isEmpty {
            throw IMPError.emptyVariants
        }

        var combinations: [[String:AnyEncodable]] = []
        for i in 0..<categories.count {
            let category = categories[i]
            var newCombinations:[[String:AnyEncodable]] = []
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
        
        let encodedVariants = try PListEncoder().encode(combinations) as! [[String:Any]]
        return Decision(self.decisionContext.chooseFrom(encodedVariants), combinations.map({
            $0.mapValues({ (v: AnyEncodable) in
                v.value
            }) as! [String : T]
        }))
    }
    
    public func chooseMultivariate(_ variants: [String : Any]) throws -> Decision<[String: Any]> {
        var categories: [[AnyEncodable]] = []
        var keys: [String] = []
        for (k, v) in variants {
            if let v = v as? [Any] {
                if !v.isEmpty {
                    categories.append(v.map{ AnyEncodable($0) })
                    keys.append(k)
                }
            } else {
                categories.append([AnyEncodable(v)])
                keys.append(k)
            }
        }
        
        if categories.isEmpty {
            throw IMPError.emptyVariants
        }

        var combinations: [[String:AnyEncodable]] = []
        for i in 0..<categories.count {
            let category = categories[i]
            var newCombinations:[[String:AnyEncodable]] = []
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
        
        let encodedVariants = try PListEncoder().encode(combinations) as! [[String:Any]]
        return Decision(self.decisionContext.chooseFrom(encodedVariants), combinations.map({
            $0.mapValues({ (v: AnyEncodable) in
                v.value
            })
        }))
    }
    
    public func optimize<T>(_ variants: [String : [T]]) throws -> [String : T] {
        return try chooseMultivariate(variants).get()
    }
    
    public func optimize(_ variants: [String : Any]) throws -> [String: Any] {
        return try chooseMultivariate(variants).get()
    }
}
