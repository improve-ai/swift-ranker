//
//  TestRewardTracker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/8.
//

import XCTest
@testable import ImproveAI

final class TestRewardTracker: XCTestCase {

    static let trackUrl = URL(string: "https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track")!
    
    let tracker = {
        var tracker = try! RewardTracker(modelName: "greetings", trackUrl: trackUrl)
        tracker.writePostData = true
        return tracker
    }()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testTrack() throws {
        let rewardId = try tracker.track(item: "hi", candidates: ["hi", "hello"])
        XCTAssertEqual(27, rewardId.count)
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(6, lastPostData.count)
        XCTAssertEqual("decision", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("hello", lastPostData["sample"] as? String)
        XCTAssertEqual("hi", lastPostData["item"] as? String)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(2, lastPostData["count"] as? Int)
    }
    
    func testTrack_null_sample() throws {
        let rewardId = try tracker.track(item: "hi", candidates: ["hi", nil])
        XCTAssertEqual(27, rewardId.count)
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(6, lastPostData.count)
        XCTAssertEqual("decision", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual(NSNull(), lastPostData["sample"] as? NSNull)
        XCTAssertEqual("hi", lastPostData["item"] as? String)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(2, lastPostData["count"] as? Int)
    }
    
    func testTrack_none_sample() throws {
        let rewardId = try tracker.track(item: "hi", candidates: ["hi"])
        XCTAssertEqual(27, rewardId.count)
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(5, lastPostData.count)
        XCTAssertEqual("decision", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("hi", lastPostData["item"] as? String)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(1, lastPostData["count"] as? Int)
    }
    
    func testTrack_context() throws {
        let rewardId = try tracker.track(item: "hi", candidates: ["hi", "hello"], context: ["lang": "en"])
        XCTAssertEqual(27, rewardId.count)
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(7, lastPostData.count)
        XCTAssertEqual("decision", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("hello", lastPostData["sample"] as? String)
        XCTAssertEqual("hi", lastPostData["item"] as? String)
        XCTAssertEqual(["lang": "en"], lastPostData["context"] as? [String : String])
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(2, lastPostData["count"] as? Int)
    }
    
    func testAddReward_nan() throws {
        do {
            try tracker.addReward(reward: Double.nan, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        } catch IMPError.invalidArgument(let reason){
            XCTAssertEqual("reward can't be NaN or Infinite", reason)
        }
    }
    
    func testAddReward_infinite() throws {
        do {
            try tracker.addReward(reward: Double.infinity, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        } catch IMPError.invalidArgument(let reason){
            XCTAssertEqual("reward can't be NaN or Infinite", reason)
        }
        
        do {
            try tracker.addReward(reward: -Double.infinity, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        } catch IMPError.invalidArgument(let reason){
            XCTAssertEqual("reward can't be NaN or Infinite", reason)
        }
    }
    
    func testAddReward_empty_rewardId() throws {
        do {
            try tracker.addReward(reward: 0.1, rewardId: "")
        } catch IMPError.invalidArgument(let reason) {
            XCTAssertEqual("Please use the rewardId returned from method track().", reason)
        }
    }
    
    func testAddReward_invalid_rewardId() throws {
        do {
            try tracker.addReward(reward: 0.1, rewardId: "2ODatv95LBsqbCgK0VDSD0h")
        } catch IMPError.invalidArgument(let reason) {
            XCTAssertEqual("Please use the rewardId returned from method track().", reason)
        }
        
        do {
            try tracker.addReward(reward: 0.1, rewardId: "2ODatv95LBsqbCgK0VDSD0hsss")
        } catch IMPError.invalidArgument(let reason) {
            XCTAssertEqual("Please use the rewardId returned from method track().", reason)
        }
    }
    
    func testAddReward() throws {
        try tracker.addReward(reward: 0.1, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(5, lastPostData.count)
        XCTAssertEqual("reward", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("2ODatv95LBsqbCgK0VDSD0hcm5n", lastPostData["decision_id"] as? String)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(0.1, lastPostData["reward"] as? Double)
    }
}

extension String {
    func toDictionary() -> [String : Any] {
        var result = [String : Any]()
        guard !self.isEmpty else { return result }
        
        guard let dataSelf = self.data(using: .utf8) else {
            return result
        }
        
        if let dic = try? JSONSerialization.jsonObject(with: dataSelf,
                           options: .mutableContainers) as? [String : Any] {
            result = dic
        }
        return result
    }
}
