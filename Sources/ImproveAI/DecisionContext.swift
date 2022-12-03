//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/23.
//

import Foundation

public struct DecisionContext {
    internal var decisionModel: DecisionModel

    internal let givens: Any?
    
    internal init(_ decisionModel: DecisionModel, _ givens: Any?) {
        self.decisionModel = decisionModel
        self.givens = givens
    }
    
    public func score<T>(_ variants:[T]) throws -> [Double] {
        return [0]
    }
    
    private func scoreInternal(_ variants:[Any], allGivens: Any?) throws {
        if variants.isEmpty {
            throw IMPError.emptyVariants
        }
        
    }
}
