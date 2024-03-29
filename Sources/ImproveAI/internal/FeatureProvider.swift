//
//  FeatureProvider.swift
//  
//
//  Created by Hongxi Pan on 2023/4/3.
//

import Foundation
import CoreML

class FeatureProvider: MLFeatureProvider {
    let featureVector: [Double]
    
    var featureNames: Set<String>
    
    let featureIndexes: [String : Int]
    
    init(featureVector: [Double], featureNames: [String], indexes: [String : Int]) {
        self.featureVector = featureVector
        self.featureNames = Set(featureNames)
        self.featureIndexes = indexes
    }
    
    func featureValue(for featureName: String) -> MLFeatureValue? {
        let index = self.featureIndexes[featureName]!
        return MLFeatureValue(double: Double(Float32(self.featureVector[index])))
    }
}
