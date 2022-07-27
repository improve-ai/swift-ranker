//
//  TestDecisionContext.swift
//  
//
//  Created by Hongxi Pan on 2022/6/12.
//

import XCTest
import ImproveAI

class TestDecisionContext: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        DecisionModel.defaultTrackURL = URL(string: "https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track")!
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func modelUrl() -> URL {
        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/songs-2.0.mlmodel.gz")!
    }
    
    func variants() ->Array<String> {
        return ["Hello World", "Howdy World", "Hi World"]
    }
    
    func givens() ->Dictionary<String, String> {
        return ["lang":"Cowboy"]
    }
    
    func model() -> DecisionModel {
        return DecisionModel(modelName: "greetings")
    }
    
    func testScore() throws {
        let scores:[Double] = try model().load(modelUrl()).given(givens()).score(variants())
        print("scores: \(scores)")
    }

    func testChooseFrom() throws {
        let greeting: String = try model().given(givens()).chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }

    func testChooseFromVariantsAndScores() throws {
        let greeting: String = try model().given(givens()).chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting)
    }

    func testChooseFirst() throws {
        let greeting: String = try model().given(givens()).chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }

    func testFirstVariadic() throws {
        let greeting: String = try model().given(givens()).first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting)
        
        let upsell = try model().given(givens()).first(["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99])
        debugPrint("upsell: ", upsell)
    }
    
    func testFirstVariadic_empty() throws {
        do {
            let _: String = try model().given(givens()).first()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testFirstVariadic_mixed_types() throws {
        let chosen = try model().given(givens()).first("hi", 1, false, 1.2)
        debugPrint("chosen: \(chosen)")
        XCTAssertEqual("hi", chosen as! String)
    }
    
    func testFirstList() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().given(givens()).first(themes)
        print("theme: \(theme)")
        XCTAssertEqual(12, theme.fontSize)
        XCTAssertEqual("#000000", theme.primaryColor)
        XCTAssertNil(theme.secondaryColor)
        XCTAssertNil(theme.padding)
        
        let upsell: [String : Any] = try model().given(givens()).first([
            ["name": "gold", "quantity": 100, "price": 1.99],
            ["name": "diamonds", "quantity": 10, "price": 2.99],
            ["name": "red scabbard", "price": 0.99]])
        debugPrint("upsell: ", upsell)
    }
    
    func testFirstList_empty() throws {
        do {
            let themes:[Theme] = []
            let _: Theme = try model().load(modelUrl()).first(themes)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testChooseRandom() throws {
        let greeting = try model().given(givens()).chooseRandom(variants())
        print("random greeting: \(greeting)")
    }

    func testRandomVariadic() throws {
        let greeting: String = try model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
        
        let upsell: [String : Any] = try model().given(nil).random(["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99])
        debugPrint("upsell: ", upsell)
    }
    
    func testRandomVariadic_empty() throws {
        do {
            let _: String = try model().given(givens()).random()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testRandomVariadic_mixed_types() throws {
        let chosen = try model().given(givens()).random("hi", 1, false, 1.2)
        debugPrint("chosen: \(chosen)")
    }
    
    func testRandomList() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().given(givens()).random(themes)
        print("theme: \(theme)")
        
        let upsell: [String : Any] = try model().given(givens()).random([
            ["name": "gold", "quantity": 100, "price": 1.99],
            ["name": "diamonds", "quantity": 10, "price": 2.99],
            ["name": "red scabbard", "price": 0.99]])
        debugPrint("upsell: ", upsell)
    }
    
    func testRandomList_empty() throws {
        do {
            let themes:[Theme] = []
            let _: Theme = try model().load(modelUrl()).random(themes)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testWhichVariadic() throws {
        let greeting: String = try model().given(givens()).which("Hello World", "Howdy World", "Hi World")
        print("greeting: \(greeting)")
    }
    
    func testWhichVariadic_empty() throws {
        do {
            let _: String = try model().given(givens()).which()
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testWhichVariadic_mixed_types() throws {
        let chosen = try model().given(givens()).which(1, "hi", false)
        debugPrint("chosen: \(chosen)")
    }
    
    func testWhichList() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().given(givens()).which(themes)
        print("theme: \(theme)")
        
        let upsell = try model().given(givens()).which([
            ["name": "gold", "quantity": 100, "price": 1.99],
            ["name": "diamonds", "quantity": 10, "price": 2.99],
            ["name": "red scabbard", "price": 0.99]])
        debugPrint("upsell: ", upsell)
    }
    
    func testWhichList_empty() throws {
        do {
            let themes:[Theme] = []
            let _: Theme = try model().load(modelUrl()).which(themes)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testChooseMultivariate() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13]]
        let decision = try model().given(nil).chooseMultivariate(variants)
        let theme = decision.get()
        debugPrint("theme: \(theme)")
        XCTAssertEqual(2, theme.count)
        XCTAssertNotNil(theme["style"])
        XCTAssertNotNil(theme["size"])
    }
    
    func testOptimize() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13]]
        let theme: [String:Any] = try model().given(nil).optimize(variants)
        debugPrint("theme: \(theme)")
        XCTAssertEqual(2, theme.count)
        XCTAssertNotNil(theme["style"])
        XCTAssertNotNil(theme["size"])
    }
}
