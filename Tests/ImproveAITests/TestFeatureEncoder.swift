//
//  TestFeatureEncoder.swift
//  
//
//  Created by Hongxi Pan on 2022/11/21.
//

import XCTest
import ImproveAI

final class TestFeatureEncoder: XCTestCase {

    var featureNames: Set<String>!
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.featureNames = Set(loadFeatureNames())
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func loadFeatureNames() -> [String] {
        let data = Bundle.stringContentOfFile(filename: "feature_names.txt")
        return data.components(separatedBy: "\n").filter { !$0.isEmpty }
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
        let modelSeed = root["model_seed"] as! Int
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
}
