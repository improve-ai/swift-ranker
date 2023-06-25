//
//  RewardTracker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/6.
//

import Foundation
import utils

enum RequestType: String {
    case decision = "decision"
    case reward = "reward"
}

fileprivate let modelNameRegex = "^[a-zA-Z0-9][\\w\\-.]{0,63}$"

/**
 Tracks items and rewards for training updated scoring models. When an item becomes causal, pass it to the track() function, which will return a rewardId and optionally cache it for this modelName. Explicitly use the rewardId to track future rewards
 associated with that item or simply use the cached rewardId by calling addReward(reward) without an explicit rewardId.
 */
public struct RewardTracker {
    
    public let modelName: String
    
    public let trackUrl: URL
    
    public let trackApiKey: String?
    
    public let cacheRewardId: Bool

    public var cachedRewardIdKey: String {
        return "ai.improve.last_reward_id-\(self.modelName)"
    }

    var writePostData = false

    /// Create an instance.
    ///
    /// - Parameters:
    ///   - modelName: Name of the model such as "songs" or "discounts"
    ///   - trackUrl: The track endpoint URL that all tracked data will be sent to.
    ///   - trackApiKey: track endpoint API key (if applicable); Can be nil.
    ///   - cacheRewardId: Determines if the track methods should cache the rewardId to be used in future calls to addReward(reward)
    public init(modelName: String, trackUrl: URL, trackApiKey: String? = nil, cacheRewardId: Bool = true) {
        assert(isValidModelName(modelName), "Invalid model name \(modelName). Must match \(modelNameRegex)")
        self.modelName = modelName
        self.trackUrl = trackUrl
        self.trackApiKey = trackApiKey
        self.cacheRewardId = cacheRewardId
    }
    
    /// Tracks the item selected from candidates and a random sample from the remaining items.
    ///
    /// - Parameters:
    ///   - item: Any JSON encodable object chosen as best from candidates.
    ///   - candidates: Collection of items from which best is chosen.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: rewardId of this track request.
    public func track<T : Equatable>(item: T?, candidates: [T?], context: Any? = nil) -> String {
        var samples = candidates
        let index = candidates.firstIndex(where: { $0 == item })
        assert(index != nil, "Candidates must include item.")
        samples.remove(at: index!)
        if samples.isEmpty {
            return track(item: item, sample: nil, numCandidates: candidates.count, context: context)
        } else {
            if let sample = samples.randomElement()! {
                return track(item: item, sample: sample, numCandidates: candidates.count, context: context)
            } else {
                return track(item: item, sample: NSNull(), numCandidates: candidates.count, context: context)
            }
        }
    }

    
    /// Tracks the item selected and a specific sample.
    ///
    /// - Parameters:
    ///   - item: The selected item.
    ///   - sample: A random sample from the candidates.
    ///   - numCandidates: Total number of candidates, including the selected item.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: rewardId of this track equest
    public func track(item: Any?, sample: Any?, numCandidates: Int, context: Any? = nil) -> String {
        let ksuid = ksuid()
        
        var body: [String : Any] = [:]
        body[Constants.Tracker.typeKey] = RequestType.decision.rawValue
        body[Constants.Tracker.modelKey] = self.modelName
        body[Constants.Tracker.countKey] = numCandidates
        body[Constants.Tracker.messageIdKey] = ksuid
        
        if let item = item {
            body[Constants.Tracker.itemKey] = item
        } else {
            body[Constants.Tracker.itemKey] = NSNull()
        }
        
        if let sample = sample {
            body[Constants.Tracker.sampleKey] = sample
        }
        
        if let context = context {
            body[Constants.Tracker.contextKey] = context
        }
        
        post(body: body)
        
        if cacheRewardId {
            UserDefaults.standard.setValue(ksuid, forKey: self.cachedRewardIdKey)
        }
        
        return ksuid
    }
    
    /// Add reward for the provided rewardId
    ///
    /// - Parameters:
    ///   - reward: The reward to add. Must not be NaN or Infinite.
    ///   - rewardId: The id that was returned from the track() methods. If nil, will use the cached rewardId for this modelName, if any
    public func addReward(reward: Double, rewardId: String? = nil) {
        assert(!reward.isNaN && !reward.isInfinite, "Reward must not be NaN or infinite.")
            
        var finalRewardId = rewardId

        if finalRewardId == nil {
            finalRewardId = UserDefaults.standard.string(forKey: self.cachedRewardIdKey)
        }

        guard let finalRewardId = finalRewardId else {
            print("[ImproveAI] RewardTracker.addReward error: No rewardId provided and no rewardId found in cache.")
            return
        }
        
        var body: [String : Any] = [:]
        body[Constants.Tracker.typeKey] = RequestType.reward.rawValue
        body[Constants.Tracker.modelKey] = self.modelName
        body[Constants.Tracker.messageIdKey] = ksuid()
        body[Constants.Tracker.decisionIdKey] = finalRewardId
        body[Constants.Tracker.rewardKey] = reward
            
        post(body: body)
    }

    /// Clears any cached rewardId for this modelName
    public func clearCachedRewardId() {
        UserDefaults.standard.removeObject(forKey: self.cachedRewardIdKey)
    }
}

extension RewardTracker {
    func post(body: [String : Any]) {
        var headers = ["Content-Type": "application/json"]
        if let trackApiKey = self.trackApiKey {
            headers[Constants.Tracker.apiKeyHeader] = trackApiKey
        }
        
        let postData: Data
        do {
            postData = try JSONEncoder().encode(AnyEncodable(body))
        } catch {
            print("[ImproveAI] error encoding JSON: \(error)")
            return
        }
        
        if writePostData {
            UserDefaults.standard.setValue(String(data: postData, encoding: .utf8), forKey: Constants.Tracker.lastPostData)
        }
        
        var request = URLRequest(url: self.trackUrl)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                print("[ImproveAI] POST error: statusCode = \(statusCode ?? 0), \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("[ImproveAI] track response: \(dataString)")
                if writePostData {
                    UserDefaults.standard.setValue(dataString, forKey: Constants.Tracker.lastPostRsp)
                }
            }
        }
        dataTask.resume()
    }
    
    func ksuid() -> String {
        let buf: [UInt8] = [UInt8](repeating: 0, count: Int(KSUID_STRING_LENGTH))
        return buf.withUnsafeBytes { ptr in
            let cbuf = UnsafeMutablePointer<UInt8>(mutating: ptr.bindMemory(to: UInt8.self).baseAddress!)
            let ret = utils.ksuid(cbuf)
            assert(ret == 0, "Failed to generate KSUID: ret = \(ret)")
            return String(cString: cbuf)
        }
    }
}

fileprivate func isValidModelName(_ modelName: String) -> Bool {
    let predicate = NSPredicate(format:"SELF MATCHES %@", modelNameRegex)
    return predicate.evaluate(with: modelName)
}

struct Constants {
    struct Tracker {
        static let typeKey = "type"
        static let modelKey = "model"
        static let itemKey = "item"
        static let countKey = "count"
        static let sampleKey = "sample"
        static let contextKey = "context"
        static let rewardKey = "reward"
        static let messageIdKey = "message_id"
        static let decisionIdKey = "decision_id"
        static let apiKeyHeader = "x-api-key"
        
        static let lastPostData = "last_post_data"
        static let lastPostRsp = "last_post_rsp"
    }
}
