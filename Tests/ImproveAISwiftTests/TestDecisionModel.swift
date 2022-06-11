//
//  Tests.swift
//  ImproveAI
//
//  Created by Hongxi Pan on 2022/5/11.
//
import XCTest
import ImproveAI
import AnyCodable

let shouldThrowError = "An error should have been thrown."

struct Theme : Encodable{
    let fontSize: Int
    let primaryColor: String
    var secondaryColor: String? = nil
    var padding: Int? = nil
}

class Tests: XCTestCase {

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
    
    func loadedModel() throws -> DecisionModel {
        return try model().load(modelUrl())
    }

    func testDecisionModel_load() throws {
        _ = try model().load(modelUrl())
    }

    func testDecisionModel_loadAsync() {
        let expectation = expectation(description: "loading model")
        model().loadAsync(modelUrl()) { decisionModel, error in
            XCTAssertNil(error)
            XCTAssertNotNil(decisionModel)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testLoadAsync_nil_completion() {
        let decisionModel = model()
        decisionModel.loadAsync(modelUrl())
        sleep(10)
        XCTAssertNotNil(decisionModel.model)
    }

    func testScore() throws {
        let scores:[Double] = try model().load(modelUrl()).score(variants())
        XCTAssertEqual(3, scores.count)
        print("scores: \(scores)")
    }

    func testChooseFrom_not_loaded() throws {
        let greeting: String = try model().chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testChooseFrom() throws {
        let decisionModel = try DecisionModel(modelName: "themes").load(modelUrl())
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")
        ]
        let theme:Theme = try decisionModel.chooseFrom(themes).get()
        debugPrint(theme)
    }

    func testChooseFromVariantsAndScores() throws {
        let greeting: String = try model().chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting)
    }
    
    func testWhich_variadic() throws {
        let greeting = try model().load(modelUrl()).which("Hello World", "Howdy World", "Hi World")
        print("which greeting: \(greeting)")
    }
    
    func testWhich_variadic_empty() throws {
        do {
            let _:String = try model().load(modelUrl()).which()
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testWhich_list() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().load(modelUrl()).which(themes)
        print("which greeting: \(theme)")
    }
    
    func testWhich_list_empty() throws {
        do {
            let themes:[Theme] = []
            let _: Theme = try model().load(modelUrl()).which(themes)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testWhich_dictionary() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "color":["#ffffff"], "width":1080]
        let chosen = try loadedModel().which(variants)
        debugPrint("chosen: ", chosen)
    }
    
    func testWhich_dictionary_empty() throws {
        do {
            let variants:[String:Any] = [:]
            let _ = try loadedModel().which(variants)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testChooseFirst() throws {
        let greeting: String = try model().chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }

    func testFirst() throws {
        let greeting: String = try model().first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting)
    }

    func testChooseRandom() throws {
        let greeting = try model().chooseRandom(variants())
        print("random greeting: \(greeting)")
    }

    func testRandom() throws {
        let greeting = try model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
    }

    func testMultiton() throws {
        let greeting: String = try DecisionModel["greetings"].chooseFrom(["hi", "hello", "hey"]).get()
        XCTAssertEqual("hi", greeting)
    }
    
    func testChooseMultiVariates() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "color":["#ffffff"], "width":1080]
        let theme = try model().chooseMultiVariate(variants).get()
        print("theme: \(theme)")
    }
}
