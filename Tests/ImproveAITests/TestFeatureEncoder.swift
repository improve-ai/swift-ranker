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
        let featureNames = ["aaaa", "bbbb", "cccc"]
        let stringTables: [String : [UInt64]] = ["aaaa": [1], "bbbb": [2], "cccc": [3]]
        let featureEncoder = try FeatureEncoder(featureNames: featureNames, stringTables: stringTables, modelSeed: 0)
        var feature: [Double] = []
        try featureEncoder.encodeFeatureVector(variant: 1, givens: nil, into: &feature)
        debugPrint("feature: \(feature)")
    }
    
//    func testFeatureEncoder() throws {
//        continueAfterFailure = false
//        let data = Bundle.stringContentOfFile(filename: "feature_encoder_test_suite.txt")
//        let allTestFileNames = data.components(separatedBy: "\n").filter { !$0.isEmpty }
//        XCTAssertGreaterThan(allTestFileNames.count, 0)
//
//        for filename in allTestFileNames {
//            print(">>> start testing: \(filename)")
//            verify(Bundle.dictFromFile(filename: filename))
//            print(">>> end testing: \(filename)")
//        }
//    }
    
//    func verify(_ root: [String : Any]) {
//        let testcase = root["test_case"] as! [String : Any]
//        let variant = testcase["variant"]!
//        let givens = testcase["givens"] as? [String : Any]
//
//        let modelSeed = root["model_seed"] as! UInt64
//        let noise = root["noise"] as! Double
//
//        let expected = root["test_output"] as! [String : Any]
//
//        let featureEncoder = FeatureEncoder(modelSeed: modelSeed, modelFeatureNames: featureNames)
//        featureEncoder.noise = noise
//        print("noise: \(featureEncoder.noise!)")
//
//        let features = try! featureEncoder.encodeVariants(variants: [variant], given: givens)
//        XCTAssertGreaterThan(features.count, 0)
//
//        let feature = features[0]
//        XCTAssertEqual(feature.count, expected.count)
//        for (key, value) in expected {
//            if let value = value as? String, value == "inf" {
//                XCTAssertTrue(feature[key]!.doubleValue.isInfinite)
//            } else {
//                if let value = value as? Double, value.isNaN {
//                    XCTAssertTrue(feature[key]!.doubleValue.isNaN)
//                } else {
//                    XCTAssertEqual((value as! NSNumber).floatValue, Float(feature[key]!.doubleValue), accuracy: 0.000000000000001)
//                }
//            }
//        }
//
//        XCTAssertNotNil(variant)
//    }
    
    // npnan.json contains NaN which is not json decodable, so test it here
//    func testNaN() {
//        let featureEncoder = FeatureEncoder(modelSeed: 1, modelFeatureNames: featureNames)
//        featureEncoder.noise = 0.8928601514360016
//
//        let variants = [Float.nan]
//
//        let features = try! featureEncoder.encodeVariants(variants: variants, given: nil)
//        XCTAssertEqual(1, features.count)
//
//        let feature = features[0]
//        XCTAssertEqual(0, feature.count)
//    }
}
