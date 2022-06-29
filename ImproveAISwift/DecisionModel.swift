import ImproveAICore

public struct DecisionModel {
    internal var decisionModel: IMPDecisionModel
    
    internal init(_ decisionModel: IMPDecisionModel) {
        self.decisionModel = decisionModel
    }
    
    public init(modelName: String) {
        self.decisionModel = IMPDecisionModel(modelName)
    }
    
    public init(modelName: String, trackURL: URL?, trackApiKey: String?) {
        self.decisionModel = IMPDecisionModel(modelName, trackURL, trackApiKey)
    }
    
    public var model: MLModel {
        return self.decisionModel.model
    }
    
    public static var defaultTrackURL: URL {
        get {
            return IMPDecisionModel.defaultTrackURL
        }
        set(url) {
            IMPDecisionModel.defaultTrackURL = url
        }
    }
    
    public static var defaultTrackApiKey: String {
        get {
            return IMPDecisionModel.defaultTrackApiKey
        }
        set(apiKey) {
            IMPDecisionModel.defaultTrackApiKey = apiKey
        }
    }
    
    public static subscript(modelName: String) -> DecisionModel {
        return DecisionModel(IMPDecisionModel.instances[modelName])
    }
    
    public func load(_ url: URL) throws -> Self {
        try self.decisionModel.load(url)
        return self
    }
    
    public func loadAsync(_ url: URL, completion handler: ((IMPDecisionModel?, Error?) -> Void)? = nil) {
        self.decisionModel.loadAsync(url, completion: handler)
    }
    
    public func given(_ givens: [String : Encodable]?) throws -> DecisionContext {
        let encodedGivens = try PListEncoder().encode(givens?.mapValues{AnyEncodable($0)}) as? [String:Any]
        return DecisionContext(decisionContext: self.decisionModel.given(encodedGivens))
    }
    
    public func score<T : Encodable>(_ variants:[T]) throws -> [Double] {
        return try given(nil).score(variants)
    }
    
    public func chooseFrom<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseFrom(variants)
    }
    
    public func chooseFrom<T : Encodable>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
        return try given(nil).chooseFrom(variants, scores)
    }
    
    public func chooseFirst<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseFirst(variants)
    }
 
    public func first<T : Encodable>(_ variants: T...) throws -> T {
        return try chooseFirst(variants).get()
    }
    
    public func chooseRandom<T : Encodable>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseRandom(variants);
    }
    
    public func random<T : Encodable>(_ variants: T...) throws -> T {
        return try chooseRandom(variants).get()
    }
    
    public func which<T : Encodable>(_ variants: T...) throws -> T {
        return try given(nil).which(variants)
    }
    
    public func which<T : Encodable>(_ variants: [T]) throws -> T {
        return try given(nil).which(variants)
    }
    
    public func which<T : Encodable>(_ variants: [String: [T]]) throws -> [String : T] {
        return try given(nil).which(variants)
    }
    
    public func which(_ variants: [String: Encodable]) throws -> [String : Any] {
        return try given(nil).which(variants)
    }
    
    // Homogeneous variants, like ["style": ["bold", "normal"], "color": ["red", "white"]]
    public func chooseMultiVariate<T : Encodable>(_ variants: [String : [T]]) throws -> Decision<[String : T]> {
        return try given(nil).chooseMultiVariate(variants)
    }
    
    // Heterogeneous variants, like ["style": ["bold", "normal"], "fontSize":[12, 13], "width": 1080]
    public func chooseMultiVariate(_ variants: [String : Encodable]) throws -> Decision<[String : Encodable]> {
        return try given(nil).chooseMultiVariate(variants)
    }
}
