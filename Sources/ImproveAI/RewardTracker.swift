//
//  RewardTracker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/6.
//

import Foundation

struct RewardTracker {
    let modelName: String
    
    let trackUrl: URL
    
    let trackApiKey: String?
    
    init(modelName: String, trackUrl: URL, trackApiKey: String? = nil) throws {
        if(!isValidModelName(modelName)) {
            throw IMPError.invalidArgument(reason: "invalid model name")
        }
        self.modelName = modelName
        self.trackUrl = trackUrl
        self.trackApiKey = trackApiKey
    }
}

fileprivate func isValidModelName(_ modelName: String) -> Bool {
    let predicate = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9][\\w\\-.]{0,63}$")
    return predicate.evaluate(with: modelName)
}
