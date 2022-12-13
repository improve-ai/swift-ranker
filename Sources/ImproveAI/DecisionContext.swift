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
}
