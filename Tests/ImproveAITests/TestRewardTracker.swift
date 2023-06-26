//
//  TestRewardTracker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/8.
//

import XCTest
@testable import ImproveAI

final class TestRewardTracker: XCTestCase {

    static let trackUrl = URL(string: "https://f6f7vxez5b5u25l2pw6qzpr7bm0qojug.lambda-url.us-east-2.on.aws/")!
    
    let tracker = {
        var tracker = RewardTracker(modelName: "greetings", trackUrl: trackUrl)
        tracker.writePostData = true
        return tracker
    }()
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func clearCachedTrackingData() {
        UserDefaults.standard.removeObject(forKey: Constants.Tracker.lastPostData)
        UserDefaults.standard.removeObject(forKey: Constants.Tracker.lastPostRsp)
    }
    
    func testTrack() throws {
        let rewardId = tracker.track(item: "hi", candidates: ["hi", "hello"])
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
    
    func testTrack_null_item() throws {
        let rewardId = tracker.track(item: nil, candidates: [nil, "hi"])
        XCTAssertEqual(27, rewardId.count)
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(6, lastPostData.count)
        XCTAssertEqual("decision", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("hi", lastPostData["sample"] as? String)
        XCTAssertEqual(NSNull(), lastPostData["item"] as? NSNull)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(2, lastPostData["count"] as? Int)
    }
    
    func testTrack_null_sample() throws {
        let rewardId = tracker.track(item: "hi", candidates: ["hi", nil])
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
        let rewardId = tracker.track(item: "hi", candidates: ["hi"])
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
        let rewardId = tracker.track(item: "hi", candidates: ["hi", "hello"], context: ["lang": "en"])
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
    
    /*
    // TODO: Can't get assertion failure expectation to work
    func testAddReward_nan() throws {
        expectFatalError() {
            self.tracker.addReward(reward: Double.nan, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        }
    }
    
    func testAddReward_infinite() throws {
        expectFatalError() {
            self.tracker.addReward(reward: Double.infinity, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        }
        
        expectFatalError() {
            self.tracker.addReward(reward: -Double.infinity, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        }
    }*/
    
    
    func testAddReward() throws {
        tracker.addReward(0.1, rewardId: "2ODatv95LBsqbCgK0VDSD0hcm5n")
        
        let lastPostData = UserDefaults.standard.string(forKey: Constants.Tracker.lastPostData)!.toDictionary()
        XCTAssertEqual(5, lastPostData.count)
        XCTAssertEqual("reward", lastPostData["type"] as? String)
        XCTAssertEqual("greetings", lastPostData["model"] as? String)
        XCTAssertEqual("2ODatv95LBsqbCgK0VDSD0hcm5n", lastPostData["decision_id"] as? String)
        XCTAssertEqual(27, (lastPostData["message_id"] as? String)?.count)
        XCTAssertEqual(0.1, lastPostData["reward"] as? Double)
    }
    
    func testTrackRequest() throws {
        clearCachedTrackingData()
        let _ = tracker.track(item: "hi", candidates: ["hi", "hello"])
        Thread.sleep(forTimeInterval: 10)
        XCTAssertEqual("{\"status\":\"success\"}", UserDefaults.standard.value(forKey: Constants.Tracker.lastPostRsp) as? String)
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
