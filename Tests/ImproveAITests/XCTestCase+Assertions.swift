//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/12/20.
//

import XCTest
import Foundation
@testable import ImproveAI

extension XCTestCase {
    func expectFatalError(expectedMessage: String, testcase: @escaping () -> Void) {

        // arrange
        let expectation = self.expectation(description: "expectingFatalError")
        var assertionMessage: String? = nil

        // override fatalError. This will terminate thread when fatalError is called.
        FatalErrorUtil.replaceFatalError { message, _, _ in
            DispatchQueue.main.async {
                assertionMessage = message
                expectation.fulfill()
            }
            repeat {
                RunLoop.current.run()
            } while(true)
            
            // This code will never be executed
            fatalError("It will never be executed")
        }

        // act, perform on separate thread to be able terminate this thread after expectation fulfill
        Thread(block: testcase).start()
        
        waitForExpectations(timeout: 1) { _ in
            // assert
            XCTAssertEqual(assertionMessage, expectedMessage)

            // clean up
            FatalErrorUtil.restoreFatalError()
        }
    }
}
