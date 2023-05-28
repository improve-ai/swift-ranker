//
//  File.swift
//
//
//  Created by Hongxi Pan on 2022/11/21.
//

import Foundation
import CoreML
import utils

fileprivate let ITEM_FEATURE_KEY = "item"

fileprivate let CONTEXT_FEATURE_KEY = "context"

fileprivate let FIRST_LEVEL_FEATURES_CHUNKS = Set([ITEM_FEATURE_KEY, CONTEXT_FEATURE_KEY])

struct FeatureEncoder {
    static let defaultNoise: Double = 0.0
    let featureNames: [String]
    
    let modelSeed: UInt32
    
    let stringTables: [StringTable]
    
    let featureIndexes: [String : Int]
    
    let plistEncoder = PListEncoder()
    
    public init(featureNames: [String], stringTables: [String : [UInt64]], modelSeed: UInt32) throws {
        self.featureNames = featureNames
        self.modelSeed = modelSeed
        self.featureIndexes = featureNames.reduce(into: [String : Int]()) { partialResult, value in
            partialResult[value] = partialResult.count
        }
        
        var tmp = Array(repeating: StringTable(stringTable: [], modelSeed: modelSeed), count: featureNames.count)
        for (featureName, table) in stringTables {
            guard let index = self.featureIndexes[featureName] else {
                throw IMPError.invalidModel(reason: "Bad model metadata")
            }
            tmp[index] = StringTable(stringTable: table, modelSeed: modelSeed)
        }
        self.stringTables = tmp
    }
    
    func encodeFeatureVector(item: Any?, context: Any?, into: inout [Double], noise: Double) throws {
        let p: (noiseShift: Double, noiseScale: Double) = getNoiseAndShiftScale(noise: noise)
        
        try self.encodeItem(item: item, into: &into, noiseShift: Float(p.noiseShift), noiseScale: Float(p.noiseScale))
        
        try self.encodeContext(context: context, into: &into, noiseShift: Float(p.noiseShift), noiseScale: Float(p.noiseScale))
    }
    
    func encodeFeatureVectors(items: [Any?], context: Any?, into: inout [[Double]], noise: Double) throws {
        for (index, item) in items.enumerated() {
            try encodeFeatureVector(item: item, context: context, into: &into[index], noise: noise)
        }
    }
}

extension FeatureEncoder {
    private func encodeItem(item: Any?, into: inout [Double], noiseShift: Float = 0.0, noiseScale: Float = 1.0) throws {
        try self.encode(obj: item, path: ITEM_FEATURE_KEY, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
    }
    
    private func encodeContext(context: Any?, into: inout [Double], noiseShift: Float = 0.0, noiseScale: Float = 1.0) throws {
        try self.encode(obj: context, path: CONTEXT_FEATURE_KEY, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
    }
    
    func encode(obj: Any?, path: String, into: inout [Double], noiseShift: Float = 0.0, noiseScale: Float = 1.0) throws {
        guard let obj = obj else {
            return
        }
        
        switch obj {
        case is NSNull:
            break
        case let obj as Int8:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as UInt8:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Int16:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as UInt16:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Int32:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as UInt32:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Int64:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as UInt64:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Int:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as UInt:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Float:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Double:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as Bool:
            encodeNumber(obj: NSNumber(value: obj), path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as NSNumber:
            encodeNumber(obj: obj, path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let obj as String:
            encodeString(obj: obj, path: path, into: &into, noiseShift: noiseShift, noiseScale:noiseScale)
        case let array as [Any?]:
            try encodeArray(array: array, path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let dict as [String : Any]:
            try encodeDict(dict: dict, path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        case let encodable as Encodable:
            try encodeEncodable(encodable: encodable, path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        default:
            throw IMPError.typeNotSupported
        }
    }
    
    func encodeNumber(obj: NSNumber, path: String, into: inout [Double], noiseShift: Float, noiseScale: Float) {
        if obj.doubleValue.isNaN {
            return
        }
        
        guard let featureIndex = self.featureIndexes[path] else {
            return
        }
        
        into[featureIndex] = sprinkle(x: obj.doubleValue, noiseShift: noiseShift, noiseScale: noiseScale)
    }
    
    func encodeString(obj: String, path: String, into: inout [Double], noiseShift: Float, noiseScale: Float) {
        guard let featureIndex = self.featureIndexes[path] else {
            return
        }
        
        let stringTable = self.stringTables[featureIndex]
        
        into[featureIndex] = sprinkle(x: stringTable.encode(string: obj), noiseShift: noiseShift, noiseScale: noiseScale)
    }
    
    func encodeArray(array: [Any?], path: String, into: inout [Double], noiseShift: Float, noiseScale: Float) throws {
        for (index, item) in array.enumerated() {
            try self.encode(obj: item, path: "\(path).\(index)", into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        }
    }
    
    func encodeDict(dict: [String : Any], path: String, into: inout [Double], noiseShift: Float, noiseScale: Float) throws {
        for (key, value) in dict {
            try self.encode(obj: value, path: "\(path).\(key)", into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
        }
    }
    
    func encodeEncodable<T: Encodable>(encodable: T, path: String, into: inout [Double], noiseShift: Float, noiseScale: Float) throws {
        let obj = try plistEncoder.encode(encodable)
        try encode(obj: obj, path: path, into: &into, noiseShift: noiseShift, noiseScale: noiseScale)
    }
    
    private func getNoiseAndShiftScale(noise: Double) -> (Double, Double) {
        // x + noise * 2 ** -142 will round to x for most values of x. Used to create
        // distinct values when x is 0.0 since x * scale would be zero
        return (noise * pow(2, -142), 1 + noise * pow(2, -17))
    }
    
    private func sprinkle(x: Double, noiseShift: Float, noiseScale: Float) -> Double {
        // x + noise_offset will round to x for most values of x
        // allows different values when x == 0.0
        return (x + Double(noiseShift)) * Double(noiseScale)
    }
}

struct StringTable {
    let modelSeed: UInt32
    
    let mask: Int
    
    let missWidth: Double
    
    let valueTable: [UInt64 : Double]
    
    init(stringTable: [UInt64], modelSeed: UInt32) {
        self.modelSeed = modelSeed
        self.mask = Self.getMask(stringTable)
        
        // empty and single entry tables will have a miss_width of 1 or range [-0.5, 0.5]
        // 2 / max_position keeps miss values from overlapping with nonzero table values
        let maxPosition = stringTable.count - 1
        self.missWidth = maxPosition < 1 ? 1 : 2.0 / Double(maxPosition)
        
        self.valueTable = stringTable.reversed().reduce(into: [UInt64 : Double]()) { partialResult, value in
            partialResult[value] = maxPosition == 0 ? 1.0 : Self.scale(value: Double(partialResult.count) / Double(maxPosition))
        }
    }
    
    func encode(string: String) -> Double {
        let stringHash = xxhash3(string, UInt64(self.modelSeed))
        if let value = self.valueTable[stringHash & UInt64(self.mask)] {
            return value
        }
        return self.encodeMiss(stringHash: stringHash)
    }
    
    func encodeMiss(stringHash: UInt64) -> Double {
        // hash to float in range [-miss_width/2, miss_width/2]
        // 32 bit mask for JS portability
        return Self.scale(value: Double((stringHash & 0xFFFFFFFF)) * pow(2, -32), width: self.missWidth)
    }
    
    func xxhash3(_ value: String, _ seed: UInt64) -> UInt64 {
        let bytes = value.utf8CString
        return bytes.withUnsafeBufferPointer { p in
            XXH3_64bits_withSeed(p.baseAddress!, value.utf8.count, seed)
        }
    }
    
    static func scale(value: Double, width: Double = 2) -> Double {
        // map value in [0, 1] to [-width/2, width/2]
        return value * width - 0.5 * width
    }
    
    static func getMask(_ stringTable: [UInt64]) -> Int {
        guard let maxValue = stringTable.max(), maxValue != 0 else {
            return 0
        }
        // find the most significant bit in the table and create a mask
        return (1 << Int(log2(Double(maxValue)) + 1)) - 1
    }
}
