//
//  Ranker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/6.
//

import Foundation

struct Ranker {
    let scorer: Scorer
    
    init(scorer: Scorer) {
        self.scorer = scorer
    }
    
    init(modelUrl: URL) throws {
        self.scorer = try Scorer(modelUrl: modelUrl)
    }
    
    public func rank<T>(items: [T]) throws -> [T] {
        let scores = try self.scorer.score(items: items)
        return try Self.rank_with_score(items: items, scores: scores)
    }
    
    public func rank<T>(items: [T], context: [Any]) throws -> [T] {
        let scores = try self.scorer.score(items: items, context: context)
        return try Self.rank_with_score(items: items, scores: scores)
    }
}

extension Ranker {
    static func rank_with_score<T>(items: [T], scores: [Double]) throws -> [T] {
        if items.count <= 0 || scores.count <= 0 {
            throw IMPError.invalidArgument(reason: "variants and scores can't be empty")
        }

        if items.count != scores.count {
            throw IMPError.invalidArgument(reason: "variants.count must equal scores.count")
        }

        var indices: [Int] = []
        for i in 0..<items.count {
            indices.append(i)
        }

        // descending
        indices.sort { scores[$0] > scores[$1] }

        return indices.map { items[$0] }
    }
}

