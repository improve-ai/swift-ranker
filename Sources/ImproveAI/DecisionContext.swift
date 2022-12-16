//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/23.
//

import Foundation

public struct DecisionContext {
    private var decisionModel: DecisionModel

    private let context: Any?
    
    init(_ decisionModel: DecisionModel, _ context: Any?) {
        self.decisionModel = decisionModel
        self.context = context
    }
    
    public func score<T>(_ variants:[T]) throws -> [Double] {
        let allGivens = getAllGivens()
        return try decisionModel.scoreInternal(variants, allGivens)
    }
    
    public func decide<T>(_ variants: [T], _ ordered: Bool = false) throws -> Decision<T> {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        
        let allGivens = self.getAllGivens()
        
        var rankedVariants: [T]
        if ordered {
            rankedVariants = variants
        } else {
            if decisionModel.isLoaded() {
                let scores = try decisionModel.scoreInternal(variants, allGivens)
                rankedVariants = try DecisionModel.rank(variants: variants, scores: scores)
            } else {
                rankedVariants = variants
            }
        }
        return Decision(model:decisionModel, ranked: rankedVariants, givens: allGivens)
    }
    
    public func which<T>(_ variants: T...) throws -> T {
        return try whichFrom(variants)
    }
    
    public func which(_ variants: Any...) throws -> Any {
        return try whichFrom(variants)
    }
    
    public func whichFrom<T>(_ variants: [T]) throws -> T {
        let decision = try decide(variants)
        decision.trackSilently()
        return decision.best
    }
    
    public func rank<T>(_ variants: [T]) throws -> [T] {
        return try decide(variants).ranked
    }
    
    public func optimize(_ variantMap: [String : Any]) throws -> [String : Any] {
        return try whichFrom(fullFactorialVariants(variantMap))
    }
    
    public func optimize<T: Decodable>(_ variantMap: [String : Any], _ type: T.Type) throws -> T {
        let dict = try optimize(variantMap)
        let data = try JSONEncoder().encode(AnyEncodable(dict))
        return try JSONDecoder().decode(type, from: data)
    }
}

extension DecisionContext {
    func getAllGivens() -> [String : Any]? {
        if let givensProvider = decisionModel.givensProvider {
            return givensProvider.givens(forModel: decisionModel, context: context)
        }
        if let context = context {
            return [GivensKey.context : context]
        }
        return nil
    }
    
    func fullFactorialVariants(_ variantMap: [String:Any]) throws -> [[String : Any]] {
        var categories: [[Any]] = []
        var keys: [String] = []
        for (k, v) in variantMap {
            if let v = v as? [Any] {
                if !v.isEmpty {
                    categories.append(v)
                    keys.append(k)
                }
            } else {
                categories.append([v])
                keys.append(k)
            }
        }
        
        if categories.isEmpty {
            throw IMPError.emptyVariants
        }

        var combinations: [[String : Any]] = []
        for i in 0..<categories.count {
            let category = categories[i]
            var newCombinations:[[String : Any]] = []
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
        return combinations
    }
}
