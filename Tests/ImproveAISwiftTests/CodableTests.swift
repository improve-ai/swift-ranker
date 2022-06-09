//
//  CodableTests.swift
//  
//
//  Created by Hongxi Pan on 2022/6/9.
//

import XCTest
import ImproveAI
import ImproveAISwift

struct Employee: Codable {
    var name: String
    var age: Int
}

class CodableTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
        
    func testEncodeAny() throws {
        let employee = Employee(name: "Tom", age: 28)
        let dict = try PListEncoder().encode(employee)
        debugPrint(dict)
    }
}
