//
//  Ranker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/6.
//

import Foundation

public struct Ranker {
    let scorer: Scorer
    
    /// Create an instance
    ///
    /// - Parameters:
    ///   - scorer: A `Scorer` instance
    init(scorer: Scorer) {
        self.scorer = scorer
    }
    
    /// Create an instance
    ///
    /// - Parameters:
    ///   - modelUrl: URL of a plain or gzip compressed CoreML model resource.
    init(modelUrl: URL) throws {
        self.scorer = try Scorer(modelUrl: modelUrl)
    }
    
    /// Rank the list of items by their scores.
    ///
    /// - Parameters:
    ///   - items: The list of items to rank.
    ///   - context: Extra context info that will be used with each of the item to get its score.
    public func rank<T>(items: [T], context: Any? = nil) throws -> [T] {
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

