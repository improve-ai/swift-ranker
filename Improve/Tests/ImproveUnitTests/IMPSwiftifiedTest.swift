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
        let context = ["language": "cowboy"]
        let variants = ["Hello World", "Howdy World", "Hi World"]
        let greeting = try DecisionModel.load(self.modelUrl()).chooseFrom(variants).given(context).get()
        XCTAssertNotNil(greeting)
        print("greeting = \(greeting!)")
    }
    
    func testDecisionModelThrowError() throws {
        let variants = ["Hello World", "Howdy World", "Hi World"]
        do {
            let greeting = try DecisionModel.load(self.modelUrl()).chooseFrom(variants).get()
            if greeting != nil {
                print("greeting = \(greeting!)")
            }
        } catch {
            print("unexpected error: \(error)")
        }
    }
    
    // Handle exception by converting Errors to Optional Values
    func testDecisionModelThrowErrorOptional() throws {
        let variants = ["Hello World", "Howdy World", "Hi World"]
        let greeting = try? DecisionModel.load(self.invalidModelUrl()).chooseFrom(variants).get();
        XCTAssertNil(greeting)
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
    }
    
    func testLoadAsync() throws {
        let ex = expectation(description: "Model loading")
        let variants = ["Hello World", "Howdy World", "Hi World"]
        DecisionModel("hello").loadAsync(self.modelUrl()) { model, err in
            let greeting = model?.chooseFrom(variants).get()
            if greeting != nil {
                print("loadAsync, greeting=\(greeting!)")
            }
            ex.fulfill()
        }
        waitForExpectations(timeout:15)
    }
    
    func modelUrl() -> URL {
        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/improveai-songs-2.0.mlmodel.gz")!
    }
    
    func invalidModelUrl() -> URL {
        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/improveai-songs-2.0.mlmodel.gz.not.exist")!
    }
}
