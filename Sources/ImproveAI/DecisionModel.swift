import Foundation

public class DecisionModel {
//    internal var decisionModel: IMPDecisionModel
    
//    internal init(_ decisionModel: IMPDecisionModel) {
//        self.decisionModel = decisionModel
//    }
    
    public let modelName: String
    
    /// The track URL to be used for tracking decisions and adding rewards.
    public var trackURL: URL?

    /// The track API key to be set in HTTP headers in track request.
    public var trackApiKey: String?
    
    // Equivalent to init(modelName, defaultTrackURL, defaultTrackApiKey)
    public convenience init(modelName: String) throws {
        try self.init(modelName: modelName, trackURL: nil, trackApiKey: nil)
    }
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - modelName: Length of modelName must be in range [1, 64]; Only alhpanumeric characters([a-zA-Z0-9]), '-', '.' and '_'
    ///   are allowed in the modenName and the first character must be an alphnumeric one.
    ///   - trackURL: The track url for this DecisionModel.
    ///   - trackApiKey: The track api key to use for this DecisionModel.
    public init(modelName: String, trackURL: URL?, trackApiKey: String?) throws {
        if(!modelName.isValidModelName()) {
            throw IMPError.invalidArgument(reason: "invalid model name")
        }
        self.modelName = modelName
        self.trackURL = trackURL
        self.trackApiKey = trackApiKey
    }
    
//    public func score(_ variants:[Any]) throws -> [Double] {
//
//    }
    
//    /// The track URL to be used for tracking decisions and adding rewards.
//    public var trackURL: URL? {
//        get {
//            return decisionModel.trackURL
//        }
//        set(url) {
//            decisionModel.trackURL = url
//        }
//    }
//    
//    /// The track API key to be set in HTTP headers in track request.
//    public var trackApiKey: String? {
//        get {
//            return decisionModel.trackApiKey
//        }
//        set(key) {
//            decisionModel.trackApiKey = key
//        }
//    }
//    
//    /// The default track URL to use for all new DecisionModel instances
//    public static var defaultTrackURL: URL? {
//        get {
//            return IMPDecisionModel.defaultTrackURL
//        }
//        set(url) {
//            IMPDecisionModel.defaultTrackURL = url
//        }
//    }
//    
//    /// The default track API key to use for all new DecisionModel instances
//    public static var defaultTrackApiKey: String? {
//        get {
//            return IMPDecisionModel.defaultTrackApiKey
//        }
//        set(key) {
//            IMPDecisionModel.defaultTrackApiKey = key
//        }
//    }
//    
//    public static var defaultGivensProvider: GivensProvider? {
//        get {
//            return IMPDecisionModel.defaultGivensProvider
//        }
//        set(provider) {
//            IMPDecisionModel.defaultGivensProvider = provider
//        }
//    }
//    
//    public var givensProvider: GivensProvider? {
//        get {
//            return decisionModel.givensProvider
//        }
//        set(provider) {
//            decisionModel.givensProvider = provider
//        }
//    }
//    
//    /// Static subscript for accessing a DecisionModel from the instances array
//    public static subscript(modelName: String) -> DecisionModel {
//        return DecisionModel(IMPDecisionModel.instances[modelName])
//    }
//    
//    /// Loads a MLModel synchronously.
//    ///
//    ///  - Parameter url: A `URL` that points to a MLModel file. It can be a local file path, a remote http url, or a bundled MLModel file.
//    ///  Urls that end with '.gz' are considered gzip compressed, and will be decompressed automatically.
//    ///  - Returns: Self.
//    ///  - Throws: An `Error` when model loading fails.
//    public func load(_ url: URL) throws -> Self {
//        try self.decisionModel.load(url)
//        return self
//    }
//    
//    /// Loads a  MLModel from the `URL`
//    ///
//    /// - Parameters:
//    ///     - url: A `URL` that points to a MLModel file. It can be a local file path, a remote http url, or a bundled MLModel file.
//    ///     Urls that end with '.gz' are considered gzip compressed, and will be decompressed automatically.
//    ///     - handler: Closure handler to be called when the model is loaded. When error is nil, the `DecisionModel` is guaranteed to be nonnull.
//    public func loadAsync(_ url: URL, completion handler: ((DecisionModel?, Error?) -> Void)? = nil) {
//        decisionModel.loadAsync(url) { decisionModel, error in
//            if error == nil {
//                self.decisionModel = decisionModel!
//            }
//            
//            if let handler = handler {
//                if error == nil {
//                    handler(self, nil)
//                } else {
//                    handler(nil, error)
//                }
//            }
//        }
//    }
//    
//    /// Adds additional context info.
//    ///
//    /// - Parameter givens: Additional context info that will be used with each of the variants to calculate the score.
//    /// - Returns: A `DecisionContext` object.
//    /// - Throws: An `Error` if givens cannot be encoded.
//    public func given(_ givens: [String : Any]?) throws -> DecisionContext {
//        guard let givens = givens else {
//            return DecisionContext(decisionContext: self.decisionModel.given(nil), decisionModel: self, givens: nil)
//        }
//        let encodedGivens = try PListEncoder().encode(givens.mapValues{AnyEncodable($0)}) as? [String:Any]
//        return DecisionContext(decisionContext: self.decisionModel.given(encodedGivens), decisionModel: self, givens: givens)
//    }
//    
//    /// Gets the scores of the variants. If the model is not loaded yet, a randomly generated list of scores in descending order would be returned.
//    ///
//    /// - Parameter variants: Variants can be any JSON encodable data structure of arbitrary complexity, including nested dictionaries,
//    /// arrays, strings, numbers, nulls, booleans, and types that conform to the `Encodable` protocol(`URL`, `Date`, `Data` excluded).
//    /// - Returns: Scores of the variants.
//    /// - Throws: An `Error` if variants is empty.
//    public func score<T>(_ variants:[T]) throws -> [Double] {
//        return try given(nil).score(variants)
//    }
//    
//    /// Chooses the best variant.
//    ///
//    /// - Parameters;
//    ///     - variants: Variants can be any JSON encodable data structure of arbitrary complexity, including nested dictionaries,
//    ///     arrays, strings, numbers, nulls, booleans, and types that conform to the `Encodable` protocol(`URL`, `Date`, `Data` excluded).
//    ///     - ordered: ordered = true means that the variants are already in order, and no scoring would be performed.
//    /// - Returns: A Decision object.
//    /// - Throws: An `Error` if variants is empty, or cannot be encoded.
//    public func decide<T>(_ variants:[T], _ ordered:Bool = false) throws -> Decision<T> {
//        return try given(nil).decide(variants, ordered)
//    }
//    
//    /// Chooses from the variants with the provided scores. The chosen variant is the one with highest score.
//    ///
//    /// - Parameters:
//    ///     - variants: Variants to choose from.
//    ///     - scores: Scores of the variants.
//    /// - Returns: A Decision object.
//    /// - Throws: An `IMPError.invalidArgument` if variants/scores is empty, or variants.count != scores.count.
//    public func decide<T>(_ variants:[T], _ scores:[Double]) throws -> Decision<T> {
//        return try given(nil).decide(variants, scores)
//    }
//    
//    /// The variadic version of whichFrom(variants).
//    public func which<T>(_ variants: T...) throws -> T {
//        return try whichFrom(variants)
//    }
//    
//    /// It exists only because we need to support different types among variants like which("hi", 1, false).
//    ///
//    /// - Parameter variants: Variants to choose from.
//    /// - Returns: The best variant.
//    public func which(_ variants: Any...) throws -> Any {
//        return try whichFrom(variants)
//    }
//    
//    /// Choose The best variant.
//    ///
//    /// - Parameter variants: Variants to choose from.
//    /// - Returns: The best variant.
//    public func whichFrom<T>(_ variants: [T]) throws -> T {
//        return try given(nil).whichFrom(variants)
//    }
//    
//    /// A shorthand of decide(variants).ranked.
//    public func rank<T>(_ variants: [T]) throws -> [T] {
//        return try given(nil).rank(variants)
//    }
//    
//    /// Generates all combinations of the variants from the variantMap, and chooses the best one.
//    /// For example, optimize(["fontSize":[12, 13], "color":["#ffffff", "#000000"], "width": 100]) would first generate
//    /// a list of variants like this:
//    /// [
//    ///    ["fontSize": 12, "color":"#ffffff", "width": 100],
//    ///    ["fontSize": 12, "color":"#000000", "width": 100],
//    ///    ["fontSize": 13, "color":"#ffffff", "width": 100],
//    ///    ["fontSize": 13, "color":"#000000", "width": 100]
//    /// ]
//    /// and then choose one of them.
//    ///
//    /// - Parameter variantMap: Vaules of the variantMap are expected to be lists of JSON encodable objects. Values that
//    /// are not lists are automatically wrapped as a list of containing a single item.
//    /// - Returns: The best variant.
//    public func optimize(_ variantMap: [String : Any]) throws -> [String : Any] {
//        return try given(nil).optimize(variantMap)
//    }
//    
//    /// Generates all combinations of the variants from the variantMap, and chooses the best one.
//    /// A handy alternative of optimize(variantMap) that would convert the chosen dict object to a Decodable object.
//    public func optimize<T: Decodable>(_ variantMap: [String : Any], _ type: T.Type) throws -> T {
//        return try given(nil).optimize(variantMap, type)
//    }
//    
//    /// Add rewards for the most recent Decision for this model name
//    ///
//    /// - Parameter reward: The reward to add.
//    /// - Throws: `IMPError.invalidArgument` if reward is NaN or Infinity.
//    public func addReward(_ reward: Double) throws {
//        if reward.isNaN || reward.isInfinite {
//            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinity.")
//        }
//        decisionModel.addReward(reward)
//    }
//    
//    /// Add reward for the decision designated by the decisionId.
//    ///
//    /// - Parameters
//    ///     - reward: The reward to add.
//    ///     - decisionId: The id of a decision.
//    /// - Throws: `IMPError.invalidArgument` if reward is NaN or Infinity; if decisionId is empty
//    public func addReward(_ reward: Double, _ decisionId: String) throws {
//        if reward.isNaN || reward.isInfinite {
//            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinity.")
//        }
//        
//        if decisionId.isEmpty {
//            throw IMPError.invalidArgument(reason: "invalid decision id.")
//        }
//        decisionModel.addReward(reward, decisionId)
//    }
//    
//    internal static func fullFactorialVariants(_ variantMap: [String:Any]) throws -> [[String : Any]] {
//        var categories: [[Any]] = []
//        var keys: [String] = []
//        for (k, v) in variantMap {
//            if let v = v as? [Any] {
//                if !v.isEmpty {
//                    categories.append(v)
//                    keys.append(k)
//                }
//            } else {
//                categories.append([v])
//                keys.append(k)
//            }
//        }
//        
//        if categories.isEmpty {
//            throw IMPError.emptyVariants
//        }
//
//        var combinations: [[String : Any]] = []
//        for i in 0..<categories.count {
//            let category = categories[i]
//            var newCombinations:[[String : Any]] = []
//            for m in 0..<category.count {
//                if combinations.count == 0 {
//                    newCombinations.append([keys[i]:category[m]])
//                } else {
//                    for n in 0..<combinations.count {
//                        var newVariant = combinations[n]
//                        newVariant[keys[i]] = category[m]
//                        newCombinations.append(newVariant)
//                    }
//                }
//            }
//            combinations = newCombinations
//        }
//        return combinations
//    }
//    
//    // MARK: Deprecated, remove in 8.0
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func chooseFrom<T>(_ variants: [T]) throws -> Decision<T> {
//        return try given(nil).chooseFrom(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func chooseFrom<T>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
//        return try given(nil).chooseFrom(variants, scores)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func chooseFirst<T>(_ variants: [T]) throws -> Decision<T> {
//        return try given(nil).chooseFirst(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func first<T>(_ variants: [T]) throws -> T {
//        return try given(nil).first(variants)
//    }
// 
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func first<T>(_ variants: T...) throws -> T {
//        return try given(nil).first(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func first(_ variants: Any...) throws -> Any {
//        return try given(nil).first(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func chooseRandom<T>(_ variants: [T]) throws -> Decision<T> {
//        return try given(nil).chooseRandom(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func random<T>(_ variants: [T]) throws -> T {
//        return try given(nil).random(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func random<T>(_ variants: T...) throws -> T {
//        return try given(nil).random(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func random(_ variants: Any...) throws -> Any {
//        return try given(nil).random(variants)
//    }
//    
//    @available(*, deprecated, message: "Remove in 8.0")
//    public func chooseMultivariate(_ variants: [String : Any]) throws -> Decision<[String : Any]> {
//        return try given(nil).chooseMultivariate(variants)
//    }
}

private extension String {
    func isValidModelName() -> Bool {
        let predicate = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9][\\w\\-.]{0,63}$")
        return predicate.evaluate(with: self)
    }
}
