//
//  TestAppGivensProvider.swift
//  
//
//  Created by Hongxi Pan on 2022/12/7.
//

import XCTest
import ImproveAI

final class TestAppGivensProvider: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func model() -> DecisionModel {
        return try! DecisionModel(modelName: "greetings")
    }
    
    func testGivensForModel() {
        let givens = AppGivensProvider.shared.givens(forModel: model(), context: nil)
        debugPrint("givens: \(givens), \(givens.count)")
    }
}
