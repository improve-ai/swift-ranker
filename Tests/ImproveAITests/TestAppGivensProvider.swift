//
//  TestAppGivensProvider.swift
//  
//
//  Created by Hongxi Pan on 2022/12/7.
//

import XCTest
import ImproveAI

final class TestAppGivensProvider: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        DecisionModel.defaultTrackURL = defaultTrackURL
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testContext() {
        let givens = AppGivensProvider.shared.givens(forModel: model(), context: "hello")
        XCTAssertEqual("hello", givens["context"] as! String)
    }

    func testGivensForModel_nil_context() {
        let givens = AppGivensProvider.shared.givens(forModel: model(), context: nil)
        debugPrint("givens: \(givens), \(givens.count)")
        XCTAssertEqual(15, givens.count)
    }
    
    func testGivensForModel_with_context() {
        let givens = AppGivensProvider.shared.givens(forModel: model(), context: "en")
        XCTAssertEqual(16, givens.count)
    }
    
    func testDecisionNumber() {
        let key = String(format: "ai.improve.decision_count-%@", "greetings")
        let beforeNumber = UserDefaults.standard.integer(forKey: key)
        let _ = try! model().which(1, 2)
        let afterNumber = UserDefaults.standard.integer(forKey: key)
        XCTAssertEqual(afterNumber, beforeNumber + 1)
        
        let givens = AppGivensProvider.shared.givens(forModel: model(), context: nil)
        XCTAssertEqual(givens["d"] as! Int, afterNumber)
    }
    
    func testRewardsOfModel() {
        let key = String(format: "ai.improve.rewards-%@", "greetings")
        let beforeReward = UserDefaults.standard.double(forKey: key)
        let model = model()
        let _ = try! model.which(1, 2, 3)
        try! model.addReward(0.1)
        let afterReward = UserDefaults.standard.double(forKey: key)
        XCTAssertEqual(afterReward, beforeReward + 0.1, accuracy: 0.0000001)
        
        let givens = AppGivensProvider.shared.givens(forModel: model, context: nil)
        XCTAssertEqual(givens["r"] as! Double, afterReward, accuracy: 0.0000001)
    }
    
    func testRewardPerDecision() {
        let model = model()
        for _ in 1...100 {
            let _ = try! model.which(1, 2, 3)
            try! model.addReward(0.1)
        }
        let decisionNumberKey = String(format: "ai.improve.decision_count-%@", "greetings")
        let rewardsKey = String(format: "ai.improve.rewards-%@", "greetings")
        let decisioNumber = UserDefaults.standard.integer(forKey: decisionNumberKey)
        let rewards = UserDefaults.standard.double(forKey: rewardsKey)
        
        let givens = AppGivensProvider.shared.givens(forModel: model, context: nil)
        XCTAssertEqual(givens["r/d"] as! Double, rewards/Double(decisioNumber), accuracy: 0.000001)
    }
    
    func testDecisionPerDay() {
        let model = model()
        let decisionNumberKey = String(format: "ai.improve.decision_count-%@", "greetings")
        let decisioNumber = UserDefaults.standard.integer(forKey: decisionNumberKey)
        let bornTime = UserDefaults.standard.double(forKey: "ai.improve.born_time")
        let days = (Date().timeIntervalSince1970 - bornTime) / 86400.0
        let givens = AppGivensProvider.shared.givens(forModel: model, context: nil)
        XCTAssertEqual(givens["d/day"] as! Double, Double(decisioNumber)/days, accuracy: 0.001)
    }
}
