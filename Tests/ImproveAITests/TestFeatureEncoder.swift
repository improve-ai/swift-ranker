//
//  TestFeatureEncoder.swift
//  
//
//  Created by Hongxi Pan on 2022/11/21.
//

import XCTest
@testable import ImproveAI

final class TestFeatureEncoder: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFeatureEncoder() throws {
        continueAfterFailure = false
        let data = Bundle.stringContentOfFile(filename: "feature_encoder_test_suite.txt")
        let allTestFileNames = data.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertGreaterThan(allTestFileNames.count, 0)

        for filename in allTestFileNames {
            print(">>> start testing: \(filename)")
            verify(Bundle.dictFromFile(filename: filename))
            print(">>> end testing: \(filename)")
        }
    }
    
    func verify(_ root: [String : Any]) {
        let featureNames = root["feature_names"] as! [String]
        let stringTables = root["string_tables"] as! [String : [UInt64]]
        let modelSeed = root["model_seed"] as! UInt32
        let noise = (root["noise"] as! NSNumber).floatValue
        
        let testcase = root["test_case"] as! [String : Any]
        guard let item = testcase["item"] else {
            XCTFail("invalid test case: 'item' missing!")
            return
        }
        let context = testcase["context"]
        var expected: [Double] = []
        if let tmp = root["test_output"] as? [Double] {
            expected = tmp
        } else if let tmp = root["test_output"] as? [String] {
            expected = tmp.map {
                switch $0 {
                case "-inf":
                    return -Double.infinity
                case "inf":
                    return Double.infinity
                default:
                    return 0
                }
            }
        } else if let tmp = root["test_output"] as? [Double?] {
            expected = tmp.map { $0 == nil ? Double.nan : $0! }
        }
        
        let featureEncoder = try! FeatureEncoder(featureNames: featureNames, stringTables: stringTables, modelSeed: modelSeed)
        
        var features = [Double](repeating: Double.nan, count: featureNames.count)
        try! featureEncoder.encodeFeatureVector(item: item, context: context, into: &features, noise: noise)
        
        XCTAssertGreaterThan(features.count, 0)
        XCTAssertEqual(expected.count, features.count)
        for i in 0..<expected.count {
            if expected[i].isNaN {
                XCTAssertTrue(features[i].isNaN)
            } else {
                XCTAssertEqual(Float(expected[i]), Float(features[i]), accuracy: 0.000001)
            }
        }
    }
    
    func testCollision() throws {
        let allTestFileNames = ["collisions_none_items_valid_context.json",
                         "collisions_valid_items_and_context.json",
                         "collisions_valid_items_no_context.json"]
        for filename in allTestFileNames {
            print(">>> start testing: \(filename)")
            try verifyCollision(Bundle.dictFromFile(filename: filename))
            print(">>> end testing: \(filename)\n")
        }
    }
    
    func verifyCollision(_ root: [String : Any]) throws {
        let featureNames = root["feature_names"] as! [String]
        let stringTables = root["string_tables"] as! [String : [UInt64]]
        let modelSeed = root["model_seed"] as! UInt32
        let noise = (root["noise"] as! NSNumber).floatValue
        let featureEncoder = try! FeatureEncoder(featureNames: featureNames, stringTables: stringTables, modelSeed: modelSeed)

        let items: [Any] = (root["test_case"] as! [String : [Any]])["items"]!
        let contexts: [Any?]? = (root["test_case"] as? [String : [Any?]])?["contexts"]
        let outputs: [[Double?]] = root["test_output"] as! [[Double?]]
        XCTAssertGreaterThan(items.count, 0)
        
        for i in 0..<items.count {
            var featureVector = [Double](repeating: Double.nan, count: featureNames.count)
            try featureEncoder.encodeFeatureVector(item: items[i], context: contexts?[i], into: &featureVector, noise: noise)
            let expected = outputs[i]
            XCTAssertEqual(expected.count, featureVector.count)
            XCTAssertGreaterThan(expected.count, 0)
            
            for j in 0..<expected.count {
                if expected[j] != nil {
                    XCTAssertEqual(expected[j]!, featureVector[j], accuracy: 0.000000000000001)
                } else {
                    XCTAssertTrue(featureVector[j].isNaN)
                }
            }
        }
    }
}
