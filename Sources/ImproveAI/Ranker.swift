/**
--------------------------------------------------------------------------------
 Ranker.swift
--------------------------------------------------------------------------------

 Created by Hongxi Pan on 2023/4/6.
*/
import Foundation

/**
 A utility for ranking items based on their scores. The Ranker struct takes a
 Scorer object or a CoreML model to evaluate and rank the given items.
 */
public struct Ranker {
    let scorer: Scorer
    
    /**
     Create a Ranker instance with a Scorer.
     
     - Parameters:
        - scorer: A `Scorer` instance.
    */
    init(scorer: Scorer) {
        self.scorer = scorer
    }
    
    /**
     Create a Ranker instance with a CoreML model.
     
     - Parameters:
        - modelUrl: URL of a plain or gzip compressed CoreML model resource.
     
     - Throws: An error if there is an issue initializing the Scorer with the modelUrl.
    */
    init(modelUrl: URL) throws {
        self.scorer = try Scorer(modelUrl: modelUrl)
    }
    
    /**
     Rank the list of items by their scores.
     
     - Parameters:
        - items: The list of items to rank.
        - context: Extra JSON encodable context info that will be used with each of the item to get its score.
     
     - Returns: An array of ranked items, sorted by their scores in descending order.
     
     - Throws: An error if there is an issue ranking the items.
    */
    public func rank<T>(items: [T], context: Any? = nil) throws -> [T] where T: Encodable {
        let scores = try self.scorer.score(items: items, context: context)
        return try Self.rank_with_score(items: items, scores: scores)
    }
}

extension Ranker {
    /**
     Rank the items based on their scores.
     
     - Parameters:
        - items: The list of items to rank.
        - scores: The list of scores corresponding to each item.
     
     - Returns: An array of ranked items, sorted by their scores in descending order.
     
     - Throws: An error if there is an issue with the input, such as empty arrays or mismatched lengths.
    */
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
