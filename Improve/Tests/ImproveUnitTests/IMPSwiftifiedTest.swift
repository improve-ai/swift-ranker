//
//  IMPSwiftifiedTest.swift
//  ImproveUnitTests
//
//  Created by PanHongxi on 5/7/21.
//  Copyright © 2021 Mind Blown Apps, LLC. All rights reserved.
//

import XCTest


// This test file is mainly used to ensure that swiftified api works
class IMPSwiftifiedTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testDecisionModel() throws {
        let modelUrl = URL(fileURLWithPath: "/Users/phx/Documents/improve-ai/TestModel.mlmodel")
        
        let greeting = DecisionModel.load(modelUrl).chooseFrom(["Hello World", "Howdy World", "Hi World"]).given(["language": "cowboy"]).get()
        if greeting != nil {
            print("greeting = \(greeting!)")
        }
    }
    
    func testDecision() throws {
        let decisionModel = DecisionModel("hello")
        let decision = Decision(decisionModel)
        
        decision.get();
    }
    
    func testTracker() throws {
        let trackerUrl = URL(string: "http://improve.ai")!
        
        let tracker = DecisionTracker(trackerUrl)
        tracker.trackEvent("event")
        
        let trackerWithAPIKey = DecisionTracker(trackerUrl, "api-key")
        trackerWithAPIKey.trackEvent("event")
    }
}
