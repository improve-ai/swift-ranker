//
//  Tests.swift
//  ImproveAI
//
//  Created by Hongxi Pan on 2022/5/11.
//
import XCTest
import ImproveAI

let shouldThrowError = "An error should have been thrown."

struct Theme : Encodable{
    let fontSize: Int
    let primaryColor: String
    var secondaryColor: String? = nil
    var padding: Int? = nil
}

struct Config: Encodable {
    let os: String
    let version: Int
    let model: Model
    
    struct Model: Encodable {
        let name: String
        let size: Int
    }
}

class TestDecisionModel: XCTestCase {

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
    
    func variants() -> [String] {
        return ["Hello World", "Howdy World", "Hi World"]
    }
    
    func emptyVariants() -> [String] {
        return []
    }
    
    func givens() -> [String : String] {
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
    
    func testGiven_encodable() throws {
        let givens: [String: Any] = ["os": "iOS", "version": 14, "model": Config.Model(name: "x", size: 12)]
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme = try model().load(modelUrl()).given(givens).chooseFrom(themes).get()
        debugPrint("theme: ", theme)
    }
    
    func testScore() throws {
        let scores:[Double] = try model().load(modelUrl()).score(variants())
        XCTAssertEqual(3, scores.count)
        print("scores: \(scores)")
    }
    
    func testScore_empty() throws {
        do {
            let _ = try model().load(modelUrl()).score(emptyVariants())
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testChooseFrom_not_loaded() throws {
        let greeting: String = try model().chooseFrom(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testChooseFrom_empty() throws {
        do {
            let _ = try model().load(modelUrl()).chooseFrom(emptyVariants())
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
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
        let decisionModel = try model().load(modelUrl())
        let greeting = try decisionModel.which("Hello World", "Howdy World", "Hi World")
        print("which greeting: \(greeting)")
        let size = try decisionModel.which(1, 2, 3)
        print("which size: \(size)")
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
    
    func testWhich_heterogeneous() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "color":["#ffffff"], "width":1080]
        let theme: [String:Any] = try model().which(variants)
        print("theme: \(theme)")
    }
    
    func testWhich_homogeneous() throws {
        let variants = ["style":["normal", "bold"], "color":["red", "black"]]
        let theme: [String: String] = try model().which(variants)
        debugPrint(theme)
        
        let persons = ["p": [Person(name: "Tom", age: 20, address: "DC"), Person(name: "Jerry", age: 20, address: "CD")]]
        let person: [String:Person] = try model().which(persons)
        debugPrint(person)
    }
    
    func testChooseFirst() throws {
        let greeting: String = try model().chooseFirst(variants()).get()
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testChooseFirst_empty() throws {
        do {
            let _ = try model().chooseFirst(emptyVariants()).get()
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testFirst() throws {
        let greeting: String = try model().first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting)
    }
    
    func testFirst_empty() throws {
        do {
            let _: String = try model().first()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testChooseRandom() throws {
        let greeting = try model().chooseRandom(variants())
        print("random greeting: \(greeting)")
    }
    
    func testChooseRandom_empty() throws {
        do {
            let _: String = try model().chooseRandom(emptyVariants()).get()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testRandom() throws {
        let greeting = try model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
    }
    
    func testRandom_empty() throws {
        do {
            let _: String = try model().random()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }

    func testMultiton() throws {
        let greeting: String = try DecisionModel["greetings"].chooseFrom(["hi", "hello", "hey"]).get()
        XCTAssertEqual("hi", greeting)
    }
    
    func testChooseMultiVariates_heterogenous() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "color":["#ffffff"], "width":1080]
        let theme: [String:Any] = try model().chooseMultiVariate(variants).get()
        print("theme: \(theme)")
    }
    
    func testChooseMultiVariate_homogeneous() throws {
        let variants = ["style":["normal", "bold"], "color":["red", "black"]]
        let theme:[String:String] = try model().chooseMultiVariate(variants).get()
        debugPrint("theme:", theme)
        
        let persons = ["p": [Person(name: "Tom", age: 20, address: "DC"), Person(name: "Jerry", age: 20, address: "CD")]]
        let person: [String:Person] = try model().chooseMultiVariate(persons).get()
        debugPrint("person: ", person)
    }
    
    func testChooseMultiVariates_original_type() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "width":1080, "p1":[Person(name: "Tom", age: 12)], "p2": Person(name: "Jerry", age: 20, address: "dc")]
        let chosen = try model().load(modelUrl()).chooseMultiVariate(variants).get()
        let _ = chosen["p1"] as! Person
        debugPrint("chosen: ", chosen)
    }
    
    func testChooseMultiVariates_typeNotSupported() throws {
        let variants = ["beg": Date(), "end": Date()]
        do {
            let _ = try model().chooseMultiVariate(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testTypeNotSupported_date() throws {
        let variants = [Date(), Date()]
        do {
            let _ = try model().chooseFrom(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testTypeNotSupported_url() throws {
        let variants = [URL(string: "http://example.com"), URL(string: "http://example.com")]
        do {
            let _ = try model().chooseFrom(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testTypeNotSupported_data() throws {
        let variants = ["hello".data(using: .utf8)]
        do {
            let _ = try model().chooseFrom(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
}
