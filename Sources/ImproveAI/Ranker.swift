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
    public init(scorer: Scorer) {
        self.scorer = scorer
    }
    
    /**
     Create a Ranker instance with a CoreML model.
     
     - Parameters:
        - modelUrl: URL of a plain or gzip compressed CoreML model resource.
     - Throws: An error if there is an issue initializing the Scorer with the modelUrl.
    */
    public init(modelUrl: URL) throws {
        self.scorer = try Scorer(modelUrl: modelUrl)
    }
    
    /**
     Rank the list of items from best to worst (highest to lowest scoring)

     - Parameters:
        - items: The list of items to rank.
     - Returns: An array of ranked items, sorted by their scores in descending order.
    */
    public func rank<T>(_ items: [T]) -> [T] where T: Encodable {
        do {
            let scores = try self.scorer.score(items)
            return Self.rank_with_score(items: items, scores: scores)
        } catch {
            print("[ImproveAI] Failed to score items: \(error)")
            return items
        }
    }
    
    /**
     Rank the list of items from best to worst (highest to lowest scoring)
     
     - Parameters:
        - items: The list of items to rank.
        - context: Extra JSON encodable context info that will be used with each of the item to get its score.
     - Returns: An array of ranked items, sorted by their scores in descending order.
    */
    public func rank<T, U>(_ items: [T], context: U?) -> [T] where T: Encodable, U: Encodable {
        do {
            let scores = try self.scorer.score(items, context: context)
            return Self.rank_with_score(items: items, scores: scores)
        } catch {
            print("[ImproveAI] Failed to score items: \(error)")
            return items
        }
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
    static func rank_with_score<T>(items: [T], scores: [Double]) -> [T] {
        assert(items.count == scores.count)
        
        var indices: [Int] = []
        for i in 0..<items.count {
            indices.append(i)
        }

        // descending
        indices.sort { scores[$0] > scores[$1] }
        
        let rankedItems = indices.map { items[$0] }

        #if DEBUG && IMPROVE_AI_DEBUG
        let sortedScores = indices.map { scores[$0] }
        dump(scores: sortedScores, items: rankedItems)
        #endif

        return rankedItems
    }

    static func dump<T: Encodable>(scores: [Double], items: [T]) {
        let leadingCount = 10
        let trailingCount = 10
        let jsonEncoder = JSONEncoder()

        if scores.count <= (leadingCount + trailingCount) {
            // dump all
            for i in 0..<scores.count {
                let itemJSONString = String(data: try! jsonEncoder.encode(items[i]), encoding: .utf8)!
                print("#\(i) score: \(scores[i]) item: \(itemJSONString)")
            }
        } else {
            // dump top N scores and items
            for i in 0..<leadingCount {
                let itemJSONString = String(data: try! jsonEncoder.encode(items[i]), encoding: .utf8)!
                print("#\(i) score: \(scores[i]) item: \(itemJSONString)")
            }

            // dump bottom N scores and items
            for i in (scores.count - trailingCount)..<scores.count {
                let itemJSONString = String(data: try! jsonEncoder.encode(items[i]), encoding: .utf8)!
                print("#\(i) score: \(scores[i]) item: \(itemJSONString)")
            }
        }
    }
}
