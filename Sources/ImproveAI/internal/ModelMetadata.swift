//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2023/4/2.
//

import Foundation

struct ModelMetadata : Decodable {
    var name: String
    var seed: UInt32
    var stringTables: [String : [UInt64]]
    var version: String
    
    init(from dict: [String : String]) throws {
        guard let versionString = dict["ai.improve.version"] else {
            throw ImproveAIError.invalidModel(reason: "'version' not found in metadata")
        }
        if !canParseVersion(versionString) {
            throw ImproveAIError.invalidModel(reason: "Major version of ImproveAI SDK(\(sdkVersion)) and extracted model version(\(versionString)) don't match!")
        }
        version = versionString
        
        seed = UInt32(dict["ai.improve.seed"]!)!
        
        let stringTablesString = dict["ai.improve.string_tables"]!
        stringTables = try JSONDecoder().decode([String : [UInt64]].self, from: stringTablesString.data(using: .utf8)!)
        
        name = dict["ai.improve.model"]!
    }
}

fileprivate func canParseVersion(_ versionString: String) -> Bool {
    let array = sdkVersion.components(separatedBy: ".")
    let prefix = "\(array[0])."
    return versionString.hasPrefix(prefix) || versionString == array[0]
}
