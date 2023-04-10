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
    let modelName: String
    
    let trackUrl: URL
    
    let trackApiKey: String?
    
    var writePostData = false
    
    public init(modelName: String, trackUrl: URL, trackApiKey: String? = nil) throws {
        if(!isValidModelName(modelName)) {
            throw IMPError.invalidArgument(reason: "invalid model name")
        }
        self.modelName = modelName
        self.trackUrl = trackUrl
        self.trackApiKey = trackApiKey
    }
    
    /// Tracks the item and the candiates that it was selected from.
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
    
    public func track(item: Any?, sample: Any?, numCandidates: Int, context: Any? = nil) throws -> String {
        guard let ksuid = try? ksuid() else {
            // We don't expect SecRandomCopyBytes() to fail in production which leads to a nil ksuid.
            // Just let it crash if that really happens.
            fatalError("Failed to generate a valid ksuid!")
        }
        
        var body: [String : Any] = [:]
        body[Constants.Tracker.typeKey] = RequestType.decision.rawValue
        body[Constants.Tracker.modelKey] = self.modelName
        body[Constants.Tracker.itemKey] = item
        body[Constants.Tracker.countKey] = numCandidates
        body[Constants.Tracker.messageIdKey] = ksuid
        
        if let sample = sample {
            body[Constants.Tracker.sampleKey] = sample
        }
        
        if let context = context {
            body[Constants.Tracker.contextKey] = context
        }
        
        try post(body: body)
        
        return ksuid
    }
    
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
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request) { data, response, error in
            if let error = error {
                let statusCode = (response as? HTTPURLResponse)?.statusCode
                print("POST error: statusCode = \(statusCode ?? 0), \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("track response: \(dataString)")
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
    }
}
