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

public struct RewardTracker {
    public let modelName: String
    
    public let trackUrl: URL
    
    public let trackApiKey: String?
    
    var writePostData = false
    
    /// Create an instance.
    ///
    /// - Parameters:
    ///   - modelName: Name of the model
    ///   - trackUrl: Improve AI AWS track endpoint URL that all tracked data will be sent to.
    ///   - trackApiKey: AWS track endpoint API key (if applicable); Can be nil.
    public init(modelName: String, trackUrl: URL, trackApiKey: String? = nil) throws {
        if(!isValidModelName(modelName)) {
            throw IMPError.invalidArgument(reason: "invalid model name")
        }
        self.modelName = modelName
        self.trackUrl = trackUrl
        self.trackApiKey = trackApiKey
    }
    
    /// Tracks the item selected from candidates and a random sample from the remaining items.
    ///
    /// - Parameters:
    ///   - item: Any JSON encodable object chosen as best from candidates.
    ///   - candidates: Collection of items from which best is chosen.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: Id of this track request.
    public func track<T : Equatable>(item: T?, candidates: [T?], context: Any? = nil) throws -> String {
        var samples = candidates
        guard let index = candidates.firstIndex(where: { $0 == item }) else { throw IMPError.invalidArgument(reason: "candidates must include item!") }
        samples.remove(at: index)
        if samples.isEmpty {
            return try track(item: item, sample: nil, numCandidates: candidates.count, context: context)
        } else {
            if let sample = samples.randomElement()! {
                return try track(item: item, sample: sample, numCandidates: candidates.count, context: context)
            } else {
                return try track(item: item, sample: NSNull(), numCandidates: candidates.count, context: context)
            }
        }
    }
    
    /// Tracks the item selected and a specific sample.
    ///
    /// - Parameters:
    ///   - item: The selected item.
    ///   - sample: A specific sample from the candidates.
    ///   - numCandidates: Total number of candidates, including the selected item.
    ///   - context: Extra context info that was used with each of the item to get its score.
    /// - Returns: Id of this track equest
    public func track(item: Any?, sample: Any?, numCandidates: Int, context: Any? = nil) throws -> String {
        guard let ksuid = try? ksuid() else {
            // We don't expect SecRandomCopyBytes() to fail in production which leads to a nil ksuid.
            // Just let it crash if that really happens.
            fatalError("Failed to generate a valid ksuid!")
        }
        
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
        
        try post(body: body)
        
        return ksuid
    }
    
    /// Add reward for the provided rewardId
    ///
    /// - Parameters:
    ///   - reward: The reward to add. Must not be NaN or Infinite.
    ///   - rewardId: The id that was returned from the track() methods.
    public func addReward(reward: Double, rewardId: String) throws {
        if reward.isNaN || reward.isInfinite {
            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinite")
        }
        
        if rewardId.isEmpty || rewardId.count != KSUID_STRING_LENGTH {
            throw IMPError.invalidArgument(reason: "Please use the rewardId returned from method track().")
        }
        
        guard let ksuid = try? ksuid() else {
            // We don't expect SecRandomCopyBytes() to fail in production which leads to a nil ksuid.
            // Just let it crash if that really happens.
            fatalError("Failed to generate a valid ksuid!")
        }
        
        var body: [String : Any] = [:]
        body[Constants.Tracker.typeKey] = RequestType.reward.rawValue
        body[Constants.Tracker.modelKey] = self.modelName
        body[Constants.Tracker.messageIdKey] = ksuid
        body[Constants.Tracker.decisionIdKey] = rewardId
        body[Constants.Tracker.rewardKey] = reward
        
        try post(body: body)
    }
}

extension RewardTracker {
    func post(body: [String : Any]) throws {
        var headers = ["Content-Type": "application/json"]
        if let trackApiKey = self.trackApiKey {
            headers[Constants.Tracker.apiKeyHeader] = trackApiKey
        }
        
        let postData = try JSONEncoder().encode(AnyEncodable(body))
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
                print("POST error: statusCode = \(statusCode ?? 0), \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("track response: \(dataString)")
                if writePostData {
                    UserDefaults.standard.setValue(dataString, forKey: Constants.Tracker.lastPostRsp)
                }
            }
        }
        dataTask.resume()
    }
    
    func ksuid() throws -> String {
        let buf: [UInt8] = [UInt8](repeating: 0, count: Int(KSUID_STRING_LENGTH))
        return try buf.withUnsafeBytes { ptr in
            let cbuf = UnsafeMutablePointer<UInt8>(mutating: ptr.bindMemory(to: UInt8.self).baseAddress!)
            let ret = utils.ksuid(cbuf)
            if ret != 0 {
                throw IMPError.internalError(reason: "failed to generate ksuid: ret = \(ret)")
            }
            return String(cString: cbuf)
        }
    }
}

fileprivate func isValidModelName(_ modelName: String) -> Bool {
    let predicate = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9][\\w\\-.]{0,63}$")
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
