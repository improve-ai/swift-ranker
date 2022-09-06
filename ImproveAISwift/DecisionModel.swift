import ImproveAICore

public class DecisionModel {
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
    
    public func loadAsync(_ url: URL, completion handler: ((DecisionModel?, Error?) -> Void)? = nil) {
        decisionModel.loadAsync(url) { decisionModel, error in
            if error == nil {
                self.decisionModel = decisionModel!
            }
            
            if let handler = handler {
                if error == nil {
                    handler(self, nil)
                } else {
                    handler(nil, error)
                }
            }
        }
    }
    
    public func given(_ givens: [String : Any]?) throws -> DecisionContext {
        if givens == nil {
            return DecisionContext(decisionContext: self.decisionModel.given(nil), decisionModel: self)
        }
        let encodedGivens = try PListEncoder().encode(givens?.mapValues{AnyEncodable($0)}) as? [String:Any]
        return DecisionContext(decisionContext: self.decisionModel.given(encodedGivens), decisionModel: self)
    }
    
    public func score<T>(_ variants:[T]) throws -> [Double] {
        return try given(nil).score(variants)
    }
    
    public func decide<T>(_ variants:[T], _ ordered:Bool = false) throws -> Decision<T> {
        return try given(nil).decide(variants, ordered)
    }
    
    public func decide<T>(_ variants:[T], _ scores:[Double]) throws -> Decision<T> {
        return try given(nil).decide(variants, scores)
    }
    
    public func which<T>(_ variants: T...) throws -> T {
        return try whichFrom(variants)
    }
    
    public func which(_ variants: Any...) throws -> Any {
        return try whichFrom(variants)
    }
    
    public func whichFrom<T>(_ variants: [T]) throws -> T {
        return try given(nil).whichFrom(variants)
    }
    
    public func rank<T>(_ variants: [T]) throws -> [T] {
        return try given(nil).rank(variants)
    }
    
    public func optimize(_ variantMap: [String : Any]) throws -> [String : Any] {
        return try given(nil).optimize(variantMap)
    }
    
    public func fullFactorialVariants(_ variantMap: [String:Any]) throws -> [[String : Any]] {
        var categories: [[Any]] = []
        var keys: [String] = []
        for (k, v) in variantMap {
            if let v = v as? [Any] {
                if !v.isEmpty {
                    categories.append(v)
                    keys.append(k)
                }
            } else {
                categories.append([v])
                keys.append(k)
            }
        }
        
        if categories.isEmpty {
            throw IMPError.emptyVariants
        }

        var combinations: [[String : Any]] = []
        for i in 0..<categories.count {
            let category = categories[i]
            var newCombinations:[[String : Any]] = []
            for m in 0..<category.count {
                if combinations.count == 0 {
                    newCombinations.append([keys[i]:category[m]])
                } else {
                    for n in 0..<combinations.count {
                        var newVariant = combinations[n]
                        newVariant[keys[i]] = category[m]
                        newCombinations.append(newVariant)
                    }
                }
            }
            combinations = newCombinations
        }
        return combinations
    }
    
    /// Add rewards for the most recent Decision for this model name
    public func addReward(_ reward: Double) {
        decisionModel.addReward(reward)
    }
    
    /// Add reward for the provided decision_id
    public func addReward(_ reward: Double, _ decisionId: String) {
        decisionModel.addReward(reward, decisionId)
    }
    
    // MARK: Deprecated, remove in 8.0
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func chooseFrom<T>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseFrom(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func chooseFrom<T>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
        return try given(nil).chooseFrom(variants, scores)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func chooseFirst<T>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseFirst(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func first<T>(_ variants: [T]) throws -> T {
        return try given(nil).first(variants)
    }
 
    @available(*, deprecated, message: "Remove in 8.0")
    public func first<T>(_ variants: T...) throws -> T {
        return try given(nil).first(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func first(_ variants: Any...) throws -> Any {
        return try given(nil).first(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func chooseRandom<T>(_ variants: [T]) throws -> Decision<T> {
        return try given(nil).chooseRandom(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func random<T>(_ variants: [T]) throws -> T {
        return try given(nil).random(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func random<T>(_ variants: T...) throws -> T {
        return try given(nil).random(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func random(_ variants: Any...) throws -> Any {
        return try given(nil).random(variants)
    }
    
    @available(*, deprecated, message: "Remove in 8.0")
    public func chooseMultivariate(_ variants: [String : Any]) throws -> Decision<[String : Any]> {
        return try given(nil).chooseMultivariate(variants)
    }
}
