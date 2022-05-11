//
//  Tests.swift
//  ImproveAI
//
//  Created by Hongxi Pan on 2022/5/11.
//
import XCTest
import ImproveAI
import ImproveAISwift

class Tests: XCTestCase {

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
    
    func model() ->DecisionModel {
        return DecisionModel("greetings")
    }
    
    func testDecisionModel_load() throws {
        try model().load(modelUrl())
    }
    
    func testDecisionModel_loadAsync() {
        let expectation = expectation(description: "loading model")
        model().loadAsync(modelUrl()) { decisionModel, error in
            XCTAssertNil(error)
            XCTAssertNotNil(decisionModel)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testDecisionModel_loadAsync_nil_completion() {
        let decisionModel = model()
        decisionModel.loadAsync(modelUrl())
        sleep(10)
        XCTAssertNotNil(decisionModel.model)
    }
    
    func testDecisionModel_score() throws {
        let scores = try model().load(modelUrl()).score(variants())
        XCTAssertEqual(3, scores.count)
        print("scores: \(scores)")
    }

    func testDecisionModel_chooseFrom() {
        let greeting = model().chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModel_chooseFromVariantsAndScores() {
        let greeting = model().chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting as! String)
    }
    
    func testDecisionModel_which() throws {
        let greeting = try model().load(modelUrl()).which("Hello World", "Howdy World", "Hi World")
        print("which greeting: \(greeting)")
    }
    
    func testDecisionModel_chooseFirst() {
        let greeting = model().chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModel_first() {
        let greeting = model().first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModel_chooseRandom() {
        let greeting = model().chooseRandom(variants())
        print("random greeting: \(greeting)")
    }
    
    func testDecisionModel_random() {
        let greeting = model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
    }
    
    func testDecisionModel_multiton() {
        let greeting = DecisionModel["greetings"].chooseFrom(["hi", "hello", "hey"]).get()
        XCTAssertEqual("hi", greeting as! String)
    }
    
    func testDecisionModelContext_score() throws {
        let scores = try model().load(modelUrl()).given(givens()).score(variants())
        XCTAssertEqual(3, scores.count)
        print("scores: \(scores)")
    }
    
    func testDecisionModelContext_chooseFrom() {
        let greeting = model().given(givens()).chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModelContext_chooseFromVariantsAndScores() {
        let greeting = model().given(givens()).chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting as! String)
    }
    
    func testDecisionModelContext_which() {
        let greeting = model().given(givens()).which("Hello World", "Howdy World", "Hi World")
        print("which greeting: \(greeting)")
    }
    
    func testDecisionModelContext_chooseFirst() {
        let greeting = model().given(givens()).chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModelContext_first() {
        let greeting = model().given(givens()).first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecisionModelContext_chooseRandom() {
        let greeting = model().given(givens()).chooseRandom(variants())
        print("random greeting: \(greeting)")
    }
    
    func testDecisionModelContext_random() {
        let greeting = model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
    }
    
    func testDecision_get() {
        let greeting = model().chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecision_peek() {
        let greeting = model().chooseFrom(variants()).peek()
        XCTAssertEqual("Hello World", greeting as! String)
    }
    
    func testDecision_addReward() {
        let decision = model().chooseFrom(variants())
        let _ = decision.get()
        decision.addReward(0.1)
    }
}
