//
//  DecisionTracker.swift
//  
//
//  Created by Hongxi Pan on 2022/12/13.
//

import Foundation
import utils

struct DecisionTracker {
    let maxRunnersUp = 50
    
    let trackURL: URL
    
    var trackApiKey: String?
    
    init(trackURL: URL, trackApiKey: String? = nil) {
        self.trackURL = trackURL
        self.trackApiKey = trackApiKey
    }
    
    func track(rankedVariants: [Any], givens: [String : Any]?, modelName: String) throws -> String {
        let best = rankedVariants[0]
        
        guard let decisionId = try self.createAndPersistDecisionId(forModel: modelName) else {
            throw IMPError.internalError(reason: "Failed to generate a valid ksuid")
        }
        
        var body: [String : Any] = [TrackerKey.type: "decision", TrackerKey.model: modelName, TrackerKey.messageId: decisionId]
        
        // set best
        body[TrackerKey.variant] = best
        
        // set count
        body[TrackerKey.count] = rankedVariants.count
        
        // set givens
        if let givens = givens {
            body[TrackerKey.givens] = givens
        }
        
        // set runners-up
        var runnersUp: [Any] = []
        if shouldTrackRunnersUp(variantsCount: rankedVariants.count) {
            runnersUp = topRunnersUp(variants: rankedVariants)
            body[TrackerKey.runners_up] = runnersUp
        }
        
        // set sample
        if let sample = sampleVariant(variants: rankedVariants, runnersUpCount: runnersUp.count) {
            body[TrackerKey.sample] = sample
        }
        
        try post(body: body)
        
        return decisionId
    }
    
    func addReward(_ reward: Double, forModel modelName: String) throws {
        guard let decisionId = lastDecisionidOfModel(modelName) else {
            print("Can't add reward as the last decisionId of model(\(modelName)) is nil")
            return
        }
        try addReward(reward, forModel: modelName, decision: decisionId)
    }
    
    func addReward(_ reward: Double, forModel modelName: String, decision decisionId: String) throws {
        if reward.isNaN || reward.isInfinite {
            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinity.")
        }
        
        let ksuid = try ksuid()
        
        var body: [String : Any] = [:]
        body[TrackerKey.type] = TrackerKey.rewardType
        body[TrackerKey.model] = modelName
        body[TrackerKey.decisionId] = decisionId
        body[TrackerKey.messageId] = ksuid
        body[TrackerKey.reward] = reward
        
        try post(body: body)
        
        AppGivensProvider.addReward(reward, forModel: modelName)
    }
}

extension DecisionTracker {
    func post(body: [String : Any]) throws {
        var headers = ["Content-Type": "application/json"]
        if let trackApiKey = self.trackApiKey {
            headers[TrackerKey.trackApiKeyHeader] = trackApiKey
        }
        
        let postData = try JSONEncoder().encode(AnyEncodable(body))
        
        var request = URLRequest(url: self.trackURL)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: OperationQueue.main)
        let dataTask = session.dataTask(with: request) { data, response, error in
            if error != nil {
                let statusCode = (response as! HTTPURLResponse).statusCode
                print("POST error: \(statusCode)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("track response: \(dataString)")
            }
        }
        dataTask.resume()
    }
    
    func shouldTrackRunnersUp(variantsCount: Int) -> Bool {
        if variantsCount <= 1 || self.maxRunnersUp == 0 {
            return false
        }
        return (Double(arc4random()) / Double(UInt32.max)) <= (1.0 / Double(min(variantsCount - 1, self.maxRunnersUp)))
    }
    
    func topRunnersUp(variants: [Any]) -> [Any] {
        return Array(variants[1..<min(self.maxRunnersUp, variants.count-1)])
    }
    
    func sampleVariant(variants: [Any], runnersUpCount: Int) -> Any? {
        let samplesCount = variants.count - 1 - runnersUpCount
        if samplesCount <= 0 {
            return nil
        }
        
        let randomIndex = Int(arc4random_uniform(UInt32(samplesCount))) + 1 + runnersUpCount
        return variants[randomIndex]
    }
    
    func createAndPersistDecisionId(forModel modelName: String) throws -> String? {
        let ksuid = try ksuid()
        let key = String(format: TrackerKey.lastDecisionIdOfModel, modelName)
        UserDefaults.standard.set(ksuid, forKey: key)
        return ksuid
    }
    
    func lastDecisionidOfModel(_ modelName: String) -> String? {
        let key = String(format: TrackerKey.lastDecisionIdOfModel, modelName)
        return UserDefaults.standard.object(forKey: key) as? String
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

struct TrackerKey {
    static let lastDecisionIdOfModel = "ai.improve.last_decision-%@"
    static let type = "type"
    static let model = "model"
    static let variant = "variant"
    static let count = "count"
    static let givens = "givens"
    static let runners_up = "runners_up"
    static let sample = "sample"
    static let messageId = "message_id"
    static let decisionId = "decision_id"
    static let reward = "reward"
    
    static let decisionType = "decision"
    static let rewardType = "reward"
    
    static let trackApiKeyHeader = "x-api-key"
}
