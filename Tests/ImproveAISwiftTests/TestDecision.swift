//
//  TestDecision.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//

import XCTest
import ImproveAI

class TestDecision: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        DecisionModel.defaultTrackURL = URL(string: "https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track")!
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func modelUrl() -> URL {
        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/songs-2.0.mlmodel.gz")!
    }
    
    func variants() ->Array<String> {
        return ["Hello World", "Howdy World", "Hi World"]
    }
    
    func givens() ->Dictionary<String, String> {
        return ["lang":"Cowboy"]
    }
    
    func model() -> DecisionModel {
        return DecisionModel(modelName: "greetings")
    }
    
    func testGet() throws {
        let greeting: String = try model().chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testGet_trackOnce_false() throws {
        let greeting: String = try model().chooseFrom(variants()).get(false)
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testRanked() throws {
        let rankedVariants = try model().decide(variants()).ranked()
        XCTAssertEqual(variants().count, rankedVariants.count)
    }
    
    func testRanked_trackOnce_false() throws {
        let rankedVariants = try model().decide(variants()).ranked(false)
        XCTAssertEqual(variants().count, rankedVariants.count)
    }

    func testDecision_peek() throws {
        let greeting: String = try model().chooseFrom(variants()).peek()
        XCTAssertTrue(greeting == variants()[0])
    }

    func testDecision_addReward() throws {
        let decision = try model().chooseFrom(variants())
        let _ = decision.get()
        decision.addReward(0.1)
    }
}
