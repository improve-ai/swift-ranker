//
//  Scorer.swift
//
//
//  Created by Hongxi Pan on 2023/4/1.
//

import Foundation
import CoreML

/**
 Scores items with optional context using a CoreML model.
 */
public struct Scorer {
    let modelUrl: URL
    
    private var model: MLModel
    
    private let metadata: ModelMetadata
    
    private let featureEncoder: FeatureEncoder
    
    private let featureNames: [String]
    
    private let lockQueue = DispatchQueue(label: "Scorer.lockQueue")
    
    /**
     Initialize a Scorer instance.
     
     - Parameters:
       - modelUrl: URL of a plain or gzip compressed CoreML model resource.
     - Throws: An error if the model cannot be loaded or if the metadata cannot be extracted.
     */
    public init(modelUrl: URL) throws {
        self.modelUrl = modelUrl
        
        let result = Self.loadModel(url: modelUrl)
        if let error = result.error {
            throw error
        }
        self.model = result.model!
        
        self.metadata = try ModelMetadata(from: model.modelDescription.metadata[.creatorDefinedKey] as! [String : String])
        self.featureNames = model.modelDescription.inputDescriptionsByName.keys.map { $0 }
        self.featureEncoder = try FeatureEncoder(featureNames: featureNames, stringTables: metadata.stringTables, modelSeed: metadata.seed)
    }
    
    /**
     Uses the model to score a list of items with the given context.
     
     - Parameters:
      - items: The list of items to score.
     - Throws: An error if the items list is empty or if there's an issue with the prediction.
     - Returns: An array of `Double` values representing the scores of the items.
     */
    public func score<T>(_ items: [T]) throws -> [Double] where T: Encodable {
        let noise = Double(arc4random()) / Double(UINT32_MAX)
        return try scoreInternal(items: items, context: nil, noise: noise)
    }
    
    /**
     Uses the model to score a list of items with the given context.
     
     - Parameters:
      - items: The list of items to score.
      - context: Extra JSON encodable context info that will be used with each of the item to get its score.
     - Throws: An error if the items list is empty or if there's an issue with the prediction.
     - Returns: An array of `Double` values representing the scores of the items.
     */
    public func score<T, U>(_ items: [T], context: U?) throws -> [Double] where T: Encodable, U: Encodable {
        let noise = Double(arc4random()) / Double(UINT32_MAX)
        return try scoreInternal(items: items, context: context, noise: noise)
    }
}

extension Scorer {
    func scoreInternal(items: [Any], context: Any? = nil, noise: Double) throws -> [Double] {
        if items.isEmpty {
            throw ImproveAIError.emptyVariants
        }
                      
        return try lockQueue.sync {
            var featureVectors = try self.featureEncoder.encodeFeatureVectors(items: items, context: context, noise: noise)
            
            let batchProvider = MLArrayBatchProvider(array: featureVectors.map{ FeatureProvider(featureVector: $0, featureNames: featureNames, indexes: self.featureEncoder.featureIndexes) })
            let predictions = try self.model.predictions(fromBatch: batchProvider)

            var result = [Double](repeating: 0, count: predictions.count)
            for i in 0..<predictions.count {
                var value = predictions.features(at: i).featureValue(for: "target")!.doubleValue
                // add a very small random number to randomly break ties
                value += (Double(arc4random()) / Double(UINT32_MAX)) * pow(2, -23)
                result[i] = value
            }
            return result
        }
    }
    
    private static func loadModel(url: URL) -> (model: MLModel?, error: Error?) {
        var model: MLModel?
        var loadError: Error?
        let group = DispatchGroup()
        group.enter()
        ModelLoader(url: url).loadAsync(url) { compiledModelURL, error in
            if error != nil {
                loadError = error
                return
            }
            
            do {
                model = try MLModel(contentsOf: compiledModelURL!)
            } catch {
                loadError = error
            }
            group.leave()
        }
        group.wait()
        return (model, loadError)
    }
}
