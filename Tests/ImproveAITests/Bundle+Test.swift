//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/22.
//

import Foundation
import ImproveAI

extension Bundle {
    static var test: Bundle {
        let bundle: Bundle
        #if SWIFT_PACKAGE
        bundle = Bundle.module
        #else
        bundle = Bundle(for: TestFeatureEncoder.self)
        #endif

        return bundle
    }
    
    static func stringContentOfFile(filename: String) -> String {
        let filePath = test.path(forResource: filename, ofType: nil)!
        return try! String(contentsOfFile: filePath)
    }
    
    static func dictFromFile(filename: String) -> [String : Any] {
        let filePath = test.path(forResource: filename, ofType: nil)!
        let data = try! Data(contentsOf: URL(fileURLWithPath: filePath))
        let json = try! JSONSerialization.jsonObject(with: data)
        return json as! Dictionary<String, Any>
    }
}
