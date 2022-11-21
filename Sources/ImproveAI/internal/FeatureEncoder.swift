//
//  File.swift
//
//
//  Created by Hongxi Pan on 2022/11/21.
//

import Foundation
import CoreML
import utils

public class FeatureEncoder {
    let modelSeed: UInt64
    
    let modelFeatureNames: Set<String>
    
    let variantSeed: UInt64
    
    let valueSeed: UInt64
    
    let givensSeed: UInt64
    
    public var noise: Double? = nil
    
    public init(modelSeed: UInt64, modelFeatureNames: Set<String>) {
        self.modelSeed = modelSeed
        self.modelFeatureNames = modelFeatureNames
        self.variantSeed = xxhash3("variant", self.modelSeed)
        self.valueSeed = xxhash3("$value", self.variantSeed)
        self.givensSeed = xxhash3("givens", self.modelSeed)
        print("model_seed: \(modelSeed), variant_seed: \(variantSeed), value_seed: \(valueSeed), givens_seed: \(givensSeed)")
    }
    
    public func encodeVariants(variants: [Any], given context: [String : Any]?) throws -> [[String : MLFeatureValue]] {
        let noise = self.noise ?? Double(arc4random()) / Double(UINT32_MAX)
        
        let contextFeatures = try self.encodeContext(context: context, noise: noise)
        
        var result:[[String : MLFeatureValue]] = []
        for variant in variants {
            var variantFeatures: [String : MLFeatureValue] = contextFeatures ?? [:]
            try result.append(self.encodeVariant(variant: variant, noise: noise, features: &variantFeatures))
        }
        
        return result
    }
    
    private func encodeContext(context: [String : Any]?, noise: Double) throws -> [String : MLFeatureValue]? {
        guard let context = context else {
            return nil
        }
        let smallNoise = shrink(noise: noise)
        var features: [String : MLFeatureValue] = [:]
        return try encodeInternal(node: context, seed: givensSeed, noise: smallNoise, features: &features)
    }
    
    private func encodeVariant(variant: Any, noise: Double, features: inout [String : MLFeatureValue]) throws -> [String : MLFeatureValue] {
        let smallNoise = shrink(noise: noise)
        if variant is Dictionary<String, Any> {
            return try self.encodeInternal(node: variant, seed: self.variantSeed, noise: smallNoise, features: &features)
        }
        return try self.encodeInternal(node: variant, seed: self.valueSeed, noise: smallNoise, features: &features)
    }
    
    private func encodeInternal(node: Any, seed: UInt64, noise: Double, features: inout [String : MLFeatureValue]) throws -> [String : MLFeatureValue] {
        switch node {
        case is NSNull:
            break
        case let node as Int8:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as UInt8:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Int16:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as UInt16:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Int32:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as UInt32:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Int64:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as UInt64:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Int:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as UInt:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Float:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Double:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as Bool:
            encodeNumber(node: NSNumber(value: node), seed: seed, noise: noise, features: &features)
        case let node as NSNumber:
            encodeNumber(node: node, seed: seed, noise: noise, features: &features)
        case let node as String:
            encodeString(node: node, seed: seed, noise: noise, features: &features)
        case let array as [Any?]:
            try encodeArray(node: array, seed: seed, noise: noise, features: &features)
        case let dict as [String : Any]:
            try encodeDict(node: dict, seed: seed, noise: noise, features: &features)
        default:
            throw IMPError.typeNotSupported
        }
        return features
    }
    
    private func encodeNumber(node: NSNumber, seed: UInt64, noise: Double, features: inout [String : MLFeatureValue]) {
        let featureName = hashToFeatureName(seed)
        if !node.doubleValue.isNaN {
            if self.modelFeatureNames.contains(featureName) {
                let curValue = features[featureName]
                var unsprinkledValue: Double = 0
                if curValue != nil {
                    unsprinkledValue = reverseSprinkle(sprinkled: curValue!.doubleValue, smallNoise: noise)
                }
                let newValue = MLFeatureValue(double: sprinkle(unsprinkledValue + node.doubleValue, noise))
                features[featureName] = newValue
            }
        }
    }
    
    private func encodeString(node: String, seed: UInt64, noise: Double, features: inout [String : MLFeatureValue]) {
        let hashed = xxhash3(node, seed)
        let featureName = hashToFeatureName(seed)
        if self.modelFeatureNames.contains(featureName) {
            let curValue = features[featureName]
            var unsprinkledValue: Double = 0
            if curValue != nil {
                unsprinkledValue = reverseSprinkle(sprinkled: curValue!.doubleValue, smallNoise: noise)
            }
            let newValue = MLFeatureValue(double: sprinkle((Double((hashed & 0xffff0000) >> 16) - 0x8000) + unsprinkledValue, noise))
            features[featureName] = newValue
        }
        
        let hashedFeatureName = hashToFeatureName(hashed)
        if self.modelFeatureNames.contains(hashedFeatureName) {
            let curHashedValue = features[hashedFeatureName]
            var unsprinkledHashedValue: Double = 0
            if curHashedValue != nil {
                unsprinkledHashedValue = reverseSprinkle(sprinkled: curHashedValue!.doubleValue, smallNoise: noise)
            }
            let newHashedValue = MLFeatureValue(double: sprinkle((Double(hashed & 0xffff) - 0x8000) + unsprinkledHashedValue, noise))
            features[hashedFeatureName] = newHashedValue
        }
    }
    
    private func encodeArray(node: [Any?], seed: UInt64, noise: Double, features: inout [String : MLFeatureValue]) throws {
        for (index, item) in node.enumerated() {
            if let item = item {
                let bytes = withUnsafeBytes(of: index.bigEndian, Array.init)
                let newSeed = xxhash3(bytes, seed)
                _ = try self.encodeInternal(node: item, seed: newSeed, noise: noise, features: &features)
            }
        }
    }
    
    private func encodeDict(node: [String : Any], seed: UInt64, noise: Double, features: inout [String : MLFeatureValue]) throws {
        for (key, value) in node {
            let newSeed = xxhash3(key, seed)
            _ = try self.encodeInternal(node: value, seed: newSeed, noise: noise, features: &features)
        }
    }
    
    private func shrink(noise: Double) -> Double {
        return noise * pow(2, -17)
    }
    
    private func sprinkle(_ value: Double, _ smallNoise: Double) -> Double {
        return (value + smallNoise) * (1 + smallNoise)
    }
    
    private func reverseSprinkle(sprinkled: Double, smallNoise: Double) -> Double {
        return sprinkled / (1 + smallNoise) - smallNoise
    }
    
    private func hashToFeatureName(_ hash: UInt64) -> String {
        var buffer: [Character] = Array(repeating: "0", count: 8)
        let ref = "0123456789abcdef"
        let hash = hash >> 32
        buffer[0] = ref[Int((hash >> 28) & 0xf)]
        buffer[1] = ref[Int((hash >> 24) & 0xf)]
        buffer[2] = ref[Int((hash >> 20) & 0xf)]
        buffer[3] = ref[Int((hash >> 16) & 0xf)]
        buffer[4] = ref[Int((hash >> 12) & 0xf)]
        buffer[5] = ref[Int((hash >> 8) & 0xf)]
        buffer[6] = ref[Int((hash >> 4) & 0xf)]
        buffer[7] = ref[Int(hash & 0xf)]
        return String(buffer)
    }
}

fileprivate func xxhash3(_ value: String, _ seed: UInt64) -> UInt64 {
    let bytes = value.utf8CString
    return bytes.withUnsafeBufferPointer { p in
        XXH3_64bits_withSeed(p.baseAddress!, value.utf8.count, seed)
    }
}

fileprivate func xxhash3(_ value: [UInt8], _ seed: UInt64) -> UInt64 {
    return value.withUnsafeBufferPointer { p in
        XXH3_64bits_withSeed(p.baseAddress!, value.count, seed)
    }
}

internal extension String {
    subscript (characterIndex: Int) -> Character {
        return self[index(startIndex, offsetBy: characterIndex)]
    }
}
