//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/21.
//

import Foundation

class FeatureEncoder {
    let modelSeed: Double
    
    let modelFeatureNames: Set<String>
    
//    let noise: Double
//    
//    let variantSeed: UInt64
//    
//    let valueSeed: UInt64
//    
//    let givensSeed: UInt64
    
    init(modelSeed: Double, modelFeatureNames: Set<String>) {
        self.modelSeed = modelSeed
        self.modelFeatureNames = modelFeatureNames
    }
}
