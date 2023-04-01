//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2023/4/3.
//

import Foundation
import CoreML

class FeatureProvider: MLFeatureProvider {
    let featureVector: [Double]
    
    var featureNames: Set<String>
    
    var curIndex = 0
    
    init(featureVector: [Double], featureNames: Set<String>) {
        self.featureVector = featureVector
        self.featureNames = featureNames
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        let value = MLFeatureValue(double: Double(Float32(self.featureVector[curIndex])))
        curIndex += 1
        return value
    }
}
