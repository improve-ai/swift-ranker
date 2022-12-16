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
    
    func track(rankedVariants: [Any], given: [String : Any]?, modelName: String) throws -> String {
        let shouldTrackRunnersUp = self.shouldTrackRunnersUp(variantsCount: rankedVariants.count)
        
        let best = rankedVariants[0]
        
        guard let decisionId = try self.createAndPersistDecisionId(forModel: modelName) else {
            throw IMPError.internalError(reason: "Failed to generate a valid ksuid")
        }
        
        return decisionId
    }
    
    func addReward(_ reward: Double, forModel modelName: String) {
        
    }
    
    func addReward(_ reward: Double, forModel modelName: String, decision decisionId: String) {
        
    }
}

extension DecisionTracker {
    func shouldTrackRunnersUp(variantsCount: Int) -> Bool {
        if variantsCount <= 1 || self.maxRunnersUp == 0 {
            return false
        }
        return (Double(arc4random()) / Double(UInt32.max)) <= (1.0 / Double(min(variantsCount - 1, self.maxRunnersUp)))
    }
    
    func createAndPersistDecisionId(forModel modelName: String) throws -> String? {
        let ksuid = try String.ksuid()
        let key = String(format: TrackerKey.lastDecisionIdOfModel, modelName)
        UserDefaults.standard.set(ksuid, forKey: key)
        return ksuid
    }
}

extension String {
    static func ksuid() throws -> String {
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
}
