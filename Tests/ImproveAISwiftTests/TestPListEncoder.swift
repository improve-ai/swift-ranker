//
//  CodableTests.swift
//  
//
//  Created by Hongxi Pan on 2022/6/9.
//

import XCTest
import ImproveAI

struct Person: Codable {
    var name: String
    var age: Int?
    var address: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
//        try container.encode(address, forKey: .address)
    }
}

class TestPListEncoder: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
        
    func testEncode() throws {
        let person = Person(name: "Tom", age: 28)
        let dict = try PListEncoder().encode(person)
        debugPrint(dict)
    }
    
    func testEncode_optional() throws {
        let person = Person(name: "Tom")
        let dict = try PListEncoder().encode(person)
        debugPrint(dict)
    }
    
    func testPV() throws {
        let person = Person(name: "Tom", age: 28)
        let dict = try PListEncoder().encode(person)
        debugPrint(dict)
    }
}
