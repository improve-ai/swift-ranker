//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/11/16.
//

import Foundation
import ImproveAI
import XCTest

class Offer: NSCopying, Codable {
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Offer(title: title, price: price)
        return copy
    }
    
    let title: String
    let price: Double
    
    init(title: String, price: Double) {
        self.title = title
        self.price = price
    }
}

class TestOrignalVariant: XCTestCase {
//    override func setUpWithError() throws {
//        // Put setup code here. This method is called before the invocation of each test method in the class.
//        DecisionModel.defaultTrackURL = URL(string: "https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track")!
//        DecisionModel.defaultTrackApiKey = "api-key"
//    }
//    
//    override func tearDownWithError() throws {
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//    
//    func modelUrl() -> URL {
//        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/songs-2.0.mlmodel.gz")!
//    }
//    
//    func model() -> DecisionModel {
//        return DecisionModel(modelName: "greetings")
//    }
//    
//    func loadedModel() throws -> DecisionModel {
//        return try model().load(modelUrl())
//    }
//        
//    func testWhich_loaded() throws {
//        let offer1 = Offer(title: "Special Offer!", price: 3.99)
//        let offer2 = Offer(title: "Limited Time!", price: 4.99)
//        let model = try loadedModel()
//        for _ in 1...100 {
//            let offer = try model.which(offer1, offer2)
//            XCTAssertTrue(offer === offer1 || offer === offer2)
//        }
//    }
//    
//    func testWhich_not_loaded() throws {
//        let offer1 = Offer(title: "Special Offer!", price: 3.99)
//        let offer2 = Offer(title: "Limited Time!", price: 4.99)
//        let model = model()
//        for _ in 1...100 {
//            let offer = try model.which(offer1, offer2)
//            XCTAssertTrue(offer === offer1)
//        }
//    }
}
