//
//  GivensProvider.swift
//  
//
//  Created by Hongxi Pan on 2022/12/7.
//

import Foundation

public protocol GivensProvider {
    func givens(forModel model: DecisionModel, context: Any?) -> [String : Any]
}
