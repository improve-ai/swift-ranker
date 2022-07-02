//
//  CodableTests.swift
//  
//
//  Created by Hongxi Pan on 2022/6/9.
//

import XCTest
import ImproveAI

extension Encodable {
  fileprivate func encode(to container: inout SingleValueEncodingContainer) throws {
    try container.encode(self)
  }
}

struct AnyEncodable : Encodable {
  var value: Encodable
  init(_ value: Encodable) {
    self.value = value
  }
  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try value.encode(to: &container)
  }
}

struct Person: Codable {
    var name: String
    var age: Int?
    var address: String?
    var nilValue: String?
    
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
    
    func testKeyedContainer() throws {
        let user = KeyedUser(name: "Tom", age: 20)
        let encoded = try PListEncoder().encode(user) as! NSDictionary
        XCTAssertEqual(1, encoded.count)
        XCTAssertEqual("Tom", encoded["name"] as! String)
    }
    
    func testUnkeyedContainer() throws {
        let user = UnkeyedUser(name: "Tom", age: nil)
        let encoded = try PListEncoder().encode(user) as! NSArray
        XCTAssertEqual(1, encoded.count)
        XCTAssertEqual("Tom", encoded[0] as! String)
    }
    
    func testEncodeNil() throws {
        let s: String? = nil
        let encoded = try PListEncoder().encode(s)
        XCTAssertTrue(type(of: encoded) == NSNull.self)
        
        let list = ["Hi", "Hello", nil]
        let encodedList = try PListEncoder().encode(list) as! NSArray
        debugPrint(encodedList)
        XCTAssertEqual(2, encodedList.count)
        XCTAssertEqual("Hi", encodedList[0] as! String)
        XCTAssertEqual("Hello", encodedList[1] as! String)
        
        let map:[String:String?] = ["color":"red", "height":"12", "width": nil]
        let encodedMap = try PListEncoder().encode(map) as! NSDictionary
        XCTAssertEqual(2, encodedMap.count)
        XCTAssertEqual("red", encodedMap["color"] as! String)
        XCTAssertEqual("12", encodedMap["height"] as! String)
    }
}

struct KeyedUser: Encodable {
    let name: String
    let age: Int?
    
    private enum CodingKeys: CodingKey {
        case name
        case age
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeNil(forKey: .age)
    }
}

struct UnkeyedUser: Encodable {
    let name: String
    let age: Int?
    
    private enum CodingKeys: CodingKey {
        case name
        case age
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(name)
        try container.encodeNil()
    }
}
