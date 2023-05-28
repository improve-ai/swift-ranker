//
//  TestScorer.swift
//  
//
//  Created by Hongxi Pan on 2023/4/1.
//

import XCTest
@testable import ImproveAI

final class TestScorer: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testVersion() {
        print("sdk version is \(sdkVersion)")
        XCTAssertEqual("8.0.0", sdkVersion)
    }
    
    func testScore() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let scores = try scorer.score(items: [1, 2, nil])
        XCTAssertEqual(3, scores.count)
    }
    
    func testScore_encodable_context() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let scores = try scorer.score(items: [1, 2, nil], context: DeviceInfo(device: "14", screenPixels: 1000000))
        print("scores: \(scores)")
        XCTAssertEqual(3, scores.count)
    }
    
    func testScore_encodable_items() throws {
        let candidate = Candidate(a: 0.0, b: B(x: [0, 1.0, 2], y: false, z: ["value": "abc"]), c: nil)
        let context = ["value": "A"]
        
        let modelUrl = Bundle.test.url(forResource: "0_and_nan.mlmodel.gz", withExtension: nil)!
        var scorer = try Scorer(modelUrl: modelUrl)
        let scores = try scorer.scoreInternal(items: [candidate], context: context, noise: 0)
        print("scores: \(scores)")
        XCTAssertEqual(scores[0], 2.9701548276917342, accuracy: 0.000001)
    }
    
    func testScore_empty() throws {
        let items: [Int] = []
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        do {
            let _ = try scorer.score(items: items)
            XCTFail("expecting an error")
        } catch {
            print("error: \(error)")
        }
    }
    
    func testInvalidModel_obselete() throws {
        let modelUrl = Bundle.test.url(forResource: "version_6_0", withExtension: "mlmodelc")!
        do {
            let _ = try Scorer(modelUrl: modelUrl)
            XCTFail("expecting .invalidModel error")
        } catch {
            XCTAssertTrue(error is IMPError)
            // Better way to compare the enum case???
            if case .invalidModel = (error as! IMPError) {
            } else {
                XCTFail("expecting .invalidModel error")
            }
        }
    }
    
    func testValidateModels() throws {
        continueAfterFailure = false
        let data = Bundle.stringContentOfFile(filename: "model_test_suite.txt")
        let testcases = data.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertGreaterThan(testcases.count, 0)
        
        for testcase in testcases {
            print("verifying \(testcase)...")
            try verifyModel(name: testcase)
        }
    }
    
    func verifyModel(name: String) throws {
        let root = Bundle.dictFromFile(filename: "\(name).json")
        let testcase = root["test_case"] as! [String : Any]
        let items = testcase["candidates"] as! [Any]
        let contexts = testcase["contexts"] as! [Any]
        let outputs = root["expected_output"] as! [Any]
        let noise = (testcase["noise"] as! NSNumber).doubleValue
        
        let modelUrl = Bundle.test.url(forResource: "\(name).mlmodel.gz", withExtension: nil)!
        var scorer = try Scorer(modelUrl: modelUrl)
//        scorer.noise = noise
        
        XCTAssertGreaterThan(contexts.count, 0)
        
        for i in 0..<contexts.count {
            let context = contexts[i]
            let output = (outputs[i] as! [String:Any])["scores"] as! [Double]
            let scores = try scorer.scoreInternal(items: items, context: context, noise: noise)
            XCTAssertEqual(output.count, scores.count)
            XCTAssertGreaterThan(scores.count, 0)
            for j in 0..<scores.count {
                print("expected: \(output[j]), real: \(scores[j])")
                XCTAssertEqual(output[j], scores[j], accuracy: 0.000004)
            }
        }
    }
}

struct Candidate: Encodable {
    let a: Double
    let b: B
    let c: Int?
}

struct B: Encodable {
    let x: [Double]
    let y: Bool
    let z: [String : String]
}

struct Context: Encodable {
    let a: [String : String]
    
}




