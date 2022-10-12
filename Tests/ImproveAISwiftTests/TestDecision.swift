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
    
    func testId() throws {
        let decision = try model().decide(variants())
        XCTAssertNil(decision.id)
        _ = decision.track()
        XCTAssertNotNil(decision.id)
        print("decision id is \(decision.id!)")
    }
    
    func testGivens() throws {
        let decision = try model().decide(variants())
        XCTAssertEqual(19, decision.givens?.count)
    }
    
    func testBest() throws {
        let best = try model().decide(variants()).best
        XCTAssertEqual(variants()[0], best)
    }
    
    func testRanked() throws {
        let rankedVariants = try model().decide(variants()).ranked
        XCTAssertEqual(variants().count, rankedVariants.count)
    }
    
    func testPeek() throws {
        let greeting: String = try model().decide(variants()).peek()
        XCTAssertEqual(variants()[0], greeting)
    }
    
    func testGet() throws {
        let greeting: String = try model().decide(variants()).get()
        XCTAssertEqual(variants()[0], greeting)
    }
    
    func testTrack() throws {
        let decision = try model().decide(variants())
        let id = decision.track()
        XCTAssertNotNil(id)
    }
    
    func testAddReward() throws {
        let decision = try model().decide(variants())
        let _ = decision.track()
        try decision.addReward(0.1)
    }
    
    func testAddRewardd_NaN() throws {
        do {
            let decision = try model().decide(variants())
            _ = decision.track()
            try decision.addReward(Double.nan)
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddRewardd_infinity() throws {
        do {
            let decision = try model().decide(variants())
            _ = decision.track()
            try decision.addReward(Double.infinity)
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddReward_before_track() throws {
        do {
            try model().decide(variants()).addReward(0.1)
        } catch IMPError.illegalState(let reason){
            print(reason)
        }
    }
}
