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

struct Person: Codable {
    var name: String
    var age: Int?
    var address: String?
    var nilValue: String?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(age, forKey: .age)
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
    
    func notExistModelURL() -> URL {
        return URL(string:"https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/not_exist.mlmodel.gz")!
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

    func testLoad() throws {
        let decisionModel = try model().load(modelUrl())
        XCTAssertNotNil(decisionModel)
    }
    
    func testLoad_invalid_url() {
        do {
            _ = try model().load(notExistModelURL())
            XCTFail("should throw exception")
        } catch {
            debugPrint("load error: \(error)")
        }
    }

    func testLoadAsync() {
        let expectation = expectation(description: "loading model")
        model().loadAsync(modelUrl()) { decisionModel, error in
            XCTAssertNil(error)
            XCTAssertNotNil(decisionModel)
            XCTAssertTrue(decisionModel! is DecisionModel)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testLoadAsync_nil_completion() {
        let decisionModel = model()
        decisionModel.loadAsync(modelUrl())
        sleep(10)
//        XCTAssertNotNil(decisionModel.model)
    }
    
    func testGiven_encodable() throws {
        let givens: [String: Encodable] = ["os": "iOS", "version": 14, "model": Config.Model(name: "x", size: 12)]
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
    
    func testDecide_ordered() throws {
        let decisionModel = try loadedModel()
        for _ in 1...5 {
            let chosen = try decisionModel.decide(["Hi", "Hello", "Hey"], true).get()
            XCTAssertEqual("Hi", chosen)
        }
    }
    
    func testDecide_not_ordered() throws {
        let chosen = try loadedModel().decide(["Hi", "Hello", "Hey"], false).get()
        print("chosen: \(chosen)")
        
        for _ in 1...5 {
            let chosen = try model().decide(["Hi", "Hello", "Hey"], false).get()
            XCTAssertEqual("Hi", chosen)
        }
    }
    
    func testScore_empty() throws {
        do {
            let _ = try model().load(modelUrl()).score(emptyVariants())
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testScore_optionals() throws {
        let scores = try loadedModel().score(["Hi", nil, nil])
        debugPrint("scores: ", scores)
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
        
        let num = try decisionModel.chooseFrom([NSNumber(value: 2), NSNumber(value:true)]).get()
        debugPrint("num: \(num)")
    }
    
    func testChooseFromVariantsAndScores() throws {
        let greeting: String = try model().chooseFrom(variants(), [0.1, 0.2, 1.0]).get()
        XCTAssertEqual("Hi World", greeting)
    }
    
    func testWhich() throws {
        let decisionModel = try model().load(modelUrl())
        
        let greeting: String = try decisionModel.which("Hello World", "Howdy World", "Hi World")
        print("which greeting: \(greeting)")
        
        let size: Int = try decisionModel.which(1, 2, 3)
        print("which size: \(size)")
        
        let upsell = try loadedModel().which(["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99])
        debugPrint("upsell: ", upsell)
    }
    
    func testWhich_empty() throws {
        do {
            let _: String = try model().which()
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testWhich_mixed_types() throws {
        let chosen = try model().which(1, "hi", false)
        debugPrint("chosen: \(chosen)")
    }
    
    func testWhich_nil_variant() throws {
        let chosen = try model().which(nil, "hi", "hello")
        XCTAssertNil(chosen)
    }
    
    func testRank() throws {
        let variants = ["Hi", "Hello", "Hey"]
        let ranked = try loadedModel().rank(variants)
        XCTAssertEqual(variants.count, ranked.count)
        debugPrint("ranked: \(ranked)")
    }

    
    func testRank_any() throws {
        let variants: [Any] = ["Hi", "Hello", "Hey", 3]
        let ranked = try loadedModel().rank(variants)
        XCTAssertEqual(variants.count, ranked.count)
        debugPrint("ranked: \(ranked)")
    }
    
    func testWhichFrom() throws {
        let decisionModel = try loadedModel()
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try decisionModel.whichFrom(themes)
        print("theme: \(theme)")
        
        let upsell = try decisionModel.whichFrom([
            ["name": "gold", "quantity": 100, "price": 1.99],
            ["name": "diamonds", "quantity": 10, "price": 2.99],
            ["name": "red scabbard", "price": 0.99]])
        debugPrint("upsell: ", upsell)
        
        let chosen = try decisionModel.whichFrom(["Hello", 1, true])
        debugPrint("chosen: \(chosen)")
    }
    
    func testWhichFrom_empty() throws {
        do {
            let themes:[Theme] = []
            let _: Theme = try loadedModel().whichFrom(themes)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
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

    func testFirstVariadic() throws {
        let greeting: String = try model().first("Hello World", "Howdy World", "Hi World")
        XCTAssertEqual("Hello World", greeting)
        
        let upsell = try model().first(["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99])
        debugPrint("upsell: ", upsell)
    }
    
    func testFirstVariadic_empty() throws {
        do {
            let _: String = try model().first()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testFirstVariadic_mixed_types() throws {
        let chosen = try model().first("hi", 1, false, 1.2)
        debugPrint("chosen: \(chosen)")
        XCTAssertEqual("hi", chosen as! String)
    }
    
    func testFirstList() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().load(modelUrl()).first(themes)
        print("theme: \(theme)")
        
        let upsell: [String : Any] = try loadedModel().first([
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

    func testRandomVariadic() throws {
        let greeting: String = try model().random("Hello World", "Howdy World", "Hi World")
        print("random greeting: \(greeting)")
        
        let upsell = try model().random(["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99])
        debugPrint("upsell: ", upsell)
    }
    
    func testRandomVariadic_empty() throws {
        do {
            let _: String = try model().random()
        }  catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testRandomVariadic_mixed_types() throws {
        let chosen = try model().random("hi", 1, false, 1.2)
        debugPrint("chosen: \(chosen)")
    }
    
    func testRandomList() throws {
        let themes = [
            Theme(fontSize: 12, primaryColor: "#000000"),
            Theme(fontSize: 13, primaryColor: "#f0f0f0"),
            Theme(fontSize: 14, primaryColor: "#ffffff")]
        let theme: Theme = try model().load(modelUrl()).random(themes)
        print("theme: \(theme)")
        
        let upsell: [String : Any] = try loadedModel().random([
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

    func testMultiton() throws {
        let greeting: String = try DecisionModel["greetings"].chooseFrom(["hi", "hello", "hey"]).get()
        XCTAssertEqual("hi", greeting)
    }
    
//    func testFullFactorialVariants() throws {
//        let variantMap = ["style":["normal", "bold"], "color":["white", "black"]]
//        let variants: [[String : String]] = try model().fullFactorialVariants(variantMap) as! [[String : String]]
//        XCTAssertEqual(4, variants.count)
//        variants.forEach {
//            XCTAssertNotNil($0["style"])
//            XCTAssertNotNil($0["color"])
//        }
//    }
//    
//    func testFullFactorialVariants_empty_dict() throws {
//        let variantMap:[String:Any] = [:]
//        do {
//            let _ = try model().fullFactorialVariants(variantMap)
//        } catch IMPError.emptyVariants {
//            return
//        }
//        XCTFail(shouldThrowError)
//    }
//    
//    func testFullFactorialVariants_heterogenous() throws {
//        let variantMap:[String:Any] = ["style":["normal", "bold"], "size":[12, 13, 14], "color":["#ffffff"], "width":1080]
//        let variants: [[String:Any]] = try model().fullFactorialVariants(variantMap)
//        debugPrint("variants: \(variants)")
//        XCTAssertEqual(6, variants.count)
//    }
    
    func testChooseMultivariate_dictionary_empty() throws {
        let variants:[String:Any] = [:]
        do {
            let _ = try loadedModel().chooseMultivariate(variants)
        } catch IMPError.emptyVariants {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testChooseMultivaraite_heterogenous() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13], "color":["#ffffff"], "width":1080]
        let theme: [String:Any] = try model().chooseMultivariate(variants).get()
        print("theme: \(theme)")
    }
    
    func testChooseMultivariate_homogeneous() throws {
        let variants = ["style":["normal", "bold"], "color":["red", "black"]]
        let theme = try model().chooseMultivariate(variants).get()
        debugPrint(theme)
        
        let persons = ["p": [Person(name: "Tom", age: 20, address: "DC"), Person(name: "Jerry", age: 20, address: "CD")]]
        let person = try model().chooseMultivariate(persons).get()
        debugPrint(person)
        let upsells = ["p":[["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99]], "q": [["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99]], "m":[1, 2, 3]]
        let upsell = try model().which(upsells)
        debugPrint("upsell: ", upsell)
    }
    
    func testChooseMultivariate_original_type() throws {
        let variants:[String:Encodable] = ["style":["normal", "bold"], "size":[12, 13], "width":1080, "p1":[Person(name: "Tom", age: 12)], "p2": Person(name: "Jerry", age: 20, address: "dc")]
        let chosen = try model().load(modelUrl()).chooseMultivariate(variants).get()
        let _ = chosen["p1"] as! Person
        debugPrint("chosen: ", chosen)
    }
    
    func testChooseMultivariate_typeNotSupported() throws {
        let variants = ["beg": Date(), "end": Date()]
        do {
            let _ = try model().optimize(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testOptimize() throws {
        let variants:[String:Any] = ["style":["normal", "bold"], "size":[12, 13]]
        let theme: [String:Any] = try model().optimize(variants)
        debugPrint("theme: \(theme)")
        XCTAssertEqual(2, theme.count)
        XCTAssertNotNil(theme["style"])
        XCTAssertNotNil(theme["size"])
    }
    
    func testOptimize_empty() throws {
        let variantMap:[String:Any] = [:]
        do {
            _ = try model().optimize(variantMap)
            XCTFail(shouldThrowError)
        } catch IMPError.emptyVariants {
        }
    }
    
    func testOptimize_empty_member() throws {
        let variants: [String:Any] = ["style":["normal", "bold"], "size":[], "color":["red", "blue"]]
        let theme = try model().optimize(variants)
        debugPrint("theme: \(theme)")
        XCTAssertEqual(2, theme.count)
        XCTAssertNotNil(theme["style"])
        XCTAssertNotNil(theme["color"])
        XCTAssertNil(theme["size"])
        
        var chosen = try model().optimize(["style":["normal", "bold"], "size":[], "color":["red", "blue"]])
        XCTAssertEqual(2, chosen.count)
        XCTAssertNotNil(chosen["style"])
        XCTAssertNotNil(chosen["color"])
        XCTAssertNil(chosen["size"])
        
        do {
            chosen = try model().optimize(["style":[]])
            XCTFail(shouldThrowError)
        } catch IMPError.emptyVariants {
        }
    }
    
    func testOptimize_heterogeneous() throws {
        let upsells = ["p":[["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99]], "q": [["name": "gold", "quantity": 100, "price": 1.99], ["name": "diamonds", "quantity": 10, "price": 2.99], ["name": "red scabbard", "price": 0.99]], "m":[1, 2, 3]]
        let upsell = try model().optimize(upsells)
        debugPrint("upsell: ", upsell)
    }
    
    func testTypeNotSupported_date() throws {
        let variants = [Date(), Date()]
        do {
            let _ = try model().decide(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testTypeNotSupported_url() throws {
        let variants = [URL(string: "http://example.com"), URL(string: "http://example.com")]
        do {
            let _ = try model().decide(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testTypeNotSupported_data() throws {
        let variants = ["hello".data(using: .utf8)]
        do {
            let _ = try model().decide(variants)
        } catch IMPError.typeNotSupported {
            return
        }
        XCTFail(shouldThrowError)
    }
    
    func testAddReward() {
        try! model().addReward(0.1)
    }
    
    func testAddRewardd_NaN() throws {
        do {
            try model().addReward(Double.nan)
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddRewardd_infinity() throws {
        do {
            try model().addReward(Double.infinity)
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddRewardForDecision() {
        try! model().addReward(0.1, "abcd")
    }
    
    func testAddRewarddForDecision_NaN() throws {
        do {
            try model().addReward(Double.nan, "abcd")
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddRewarddForDecision_infinity() throws {
        do {
            try model().addReward(Double.infinity, "abcd")
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
    
    func testAddRewarddForDecision_empty_id() throws {
        do {
            try model().addReward(0.1, "")
            XCTFail(shouldThrowError)
        } catch IMPError.invalidArgument(let reason){
            print(reason)
        }
    }
}
