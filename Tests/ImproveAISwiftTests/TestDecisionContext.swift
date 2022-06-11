//
//  TestDecisionContext.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//

import XCTest
import ImproveAI

class TestDecisionContext: XCTestCase {
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
    
    func testScore() throws {
        let scores:[Double] = try model().load(modelUrl()).given(givens()).score(variants())
        print("scores: \(scores)")
    }

    func testChooseFrom() throws {
        let greeting: String = try model().given(givens()).chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }

    func testChooseFromVariantsAndScores() throws {
        let greeting: String = try model().given(givens()).chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting)
    }

    func testChooseFirst() throws {
        let greeting: String = try model().given(givens()).chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }

    func testFirst() throws {
        let greeting: String = try model().given(givens()).first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting)
    }

    func testChooseRandom() throws {
        let greeting = try model().given(givens()).chooseRandom(variants())
        print("random greeting: \(greeting)")
    }

    func testRandom() throws {
        let greeting = try model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
    }
}
