//
//  TestRanker.swift
//  
//
//  Created by Hongxi Pan on 2023/4/6.
//

import XCTest
@testable import ImproveAI

struct Theme: Encodable {
    let font: String
    let size: Int
}

final class TestRanker: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testRank_init_url() throws {
        let ranker = try Ranker(modelUrl: bundledV8ModelUrl)
        let ranked = try ranker.rank(items: ["hi", "hello", "hey"])
        print("ranked: \(ranked)")
        XCTAssertEqual(3, ranked.count)
    }
    
    func testRank_init_scorer() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let ranker = Ranker(scorer: scorer)
        let ranked = try ranker.rank(items: ["hi", "hello", "hey"])
        print("ranked: \(ranked)")
        XCTAssertEqual(3, ranked.count)
    }
    
    func testRank() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let ranker = Ranker(scorer: scorer)
        let ranked = try ranker.rank(items: [1, 2, 3])
        print("ranked: \(ranked)")
        XCTAssertEqual(3, ranked.count)
    }
    
    func testRank_Encodable() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let ranker = Ranker(scorer: scorer)
        let ranked = try ranker.rank(items: [Theme(font: "helvetica", size: 12), Theme(font: "Comic Sans", size: 16)])
        print("ranked: \(ranked)")
        XCTAssertEqual(2, ranked.count)
    }
    
    func testRank_int_context() throws {
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let ranker = Ranker(scorer: scorer)
        let ranked = try ranker.rank(items: [1, 2, 3], context: 99)
        print("ranked: \(ranked)")
        XCTAssertEqual(3, ranked.count)
    }
    
    func testRank_dict_context() throws {
        let context: [String : Any] = ["name": "diamond", "price": 99.99]
        let scorer = try Scorer(modelUrl: bundledV8ModelUrl)
        let ranker = Ranker(scorer: scorer)
        let ranked = try ranker.rank(items: [1, 2, 3], context: context)
        print("ranked: \(ranked)")
        XCTAssertEqual(3, ranked.count)
    }
    
    func testRankWithScores() throws {
        var variants: [Int] = []
        var scores: [Double] = []
        for i in -100...100 {
            variants.append(i)
            scores.append(Double(i))
        }
        
        // shuffle
        for _ in 0...100 {
            let i = Int.random(in: 0...200)
            let j = Int.random(in: 0...200)
            variants.swapAt(i, j)
            scores.swapAt(i, j)
        }
        debugPrint("before: \(variants)")
        let ranked = try Ranker.rank_with_score(items: variants, scores: scores)
        debugPrint("after: \(ranked)")
        
        for i in 0..<200 {
            XCTAssertTrue(ranked[i] > ranked[i+1])
        }
    }
}
