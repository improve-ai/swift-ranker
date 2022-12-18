import Foundation
import CoreML

public typealias LoadModelCompletionBlock = (DecisionModel?, Error?) -> Void

public class DecisionModel {
    public let modelName: String
    
    /// The track URL to be used for tracking decisions and adding rewards.
    public var trackURL: URL?

    /// The track API key to be set in HTTP headers in track request.
    public var trackApiKey: String?
    
    public static var defaultTrackURL: URL?
    
    public static var defaultTrackApiKey: String?
    
    var tracker: DecisionTracker?
    
    private var model: MLModel?
    
    private var featureEncoder: FeatureEncoder?
    
    public var givensProvider: GivensProvider?
    
    public static var defaultGivensProvider: GivensProvider? = AppGivensProvider.shared
    
    private let lockQueue = DispatchQueue(label: "DecisionModel.lockQueue")
        
    // Equivalent to init(modelName, defaultTrackURL, defaultTrackApiKey)
    public convenience init(modelName: String) throws {
        try self.init(modelName: modelName, trackURL: Self.defaultTrackURL, trackApiKey: Self.defaultTrackApiKey)
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
    
    private func setModel(_ model: MLModel) throws {
        try lockQueue.sync {
            let creatorDefined = model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey] as! [String : Any]
            
            let versionString = creatorDefined["ai.improve.version"] as? String
            if !canParseVersion(versionString) {
                throw IMPError.invalidModel(reason: "Major version of ImproveAI SDK(\(version)) and extracted model version(\(versionString ?? "")) don't match!")
            }
            
            let seedString = creatorDefined["ai.improve.model.seed"] as! String
            let seed = UInt64(seedString)!
            
            let modelName = creatorDefined["ai.improve.model.name"] as! String
            if modelName != self.modelName {
                print("Model names don't match: current model name is [\(self.modelName)] and the one extracted is [\(modelName)]. [\(self.modelName)] will be used.")
            }
            
            let featureNames = Set(model.modelDescription.inputDescriptionsByName.keys)
//            self.featureEncoder = FeatureEncoder(modelSeed: seed, modelFeatureNames: featureNames)
            
            self.model = model
        }
    }
    
    public func load(_ url: URL) throws -> Self {
        let group = DispatchGroup()
        var err: Error?
        group.enter()
        self.loadAsync(url) { decisionModel, error in
            err = error
            group.leave()
        }
        group.wait()
        
        if let err = err {
            throw err
        }
        return self
    }
    
    /// Loads a  MLModel from the `URL`
    ///
    /// - Parameters:
    ///     - url: A `URL` that points to a MLModel file. It can be a local file path, a remote http url, or a bundled MLModel file.
    ///     Urls that end with '.gz' are considered gzip compressed, and will be decompressed automatically.
    ///     - handler: Closure handler to be called when the model is loaded. When error is nil, the `DecisionModel` is guaranteed to be nonnull.
    public func loadAsync(_ url: URL, completion handler: LoadModelCompletionBlock? = nil) {
        ModelLoader(url: url).loadAsync(url) { compiledModelURL, error in
            if let error = error {
                handler?(nil, error)
                return
            }
            
            do {
                let model = try MLModel(contentsOf: compiledModelURL!)
                
                try self.setModel(model)
                
                handler?(self, nil)
            } catch {
                handler?(nil, error)
            }
        }
    }
    
    public func given(_ context: Any?) -> DecisionContext {
        return DecisionContext(self, context)
    }
    
    /// Gets the scores of the variants. If the model is not loaded yet, a randomly generated list of scores in descending order would be returned.
    ///
    /// - Parameter variants: Variants can be any JSON encodable data structure of arbitrary complexity, including nested dictionaries,
    /// arrays, strings, numbers, nulls, booleans, and types that conform to the `Encodable` protocol(`URL`, `Date`, `Data` excluded).
    /// - Returns: Scores of the variants.
    /// - Throws: An `Error` if variants is empty.
    public func score<T>(_ variants:[T]) throws -> [Double] {
        return try given(nil).score(variants)
    }
    
    /// Chooses the best variant.
    ///
    /// - Parameters;
    ///     - variants: Variants can be any JSON encodable data structure of arbitrary complexity, including nested dictionaries,
    ///     arrays, strings, numbers, nulls, booleans, and types that conform to the `Encodable` protocol(`URL`, `Date`, `Data` excluded).
    ///     - ordered: ordered = true means that the variants are already in order, and no scoring would be performed.
    /// - Returns: A Decision object.
    /// - Throws: An `Error` if variants is empty, or cannot be encoded.
    public func decide<T>(_ variants:[T], _ ordered:Bool = false) throws -> Decision<T> {
        return try given(nil).decide(variants, ordered)
    }
    
    /// The variadic version of whichFrom(variants).
    public func which<T>(_ variants: T...) throws -> T {
        return try whichFrom(variants)
    }
    
    /// It exists only because we need to support different types among variants like which("hi", 1, false).
    ///
    /// - Parameter variants: Variants to choose from.
    /// - Returns: The best variant.
    public func which(_ variants: Any...) throws -> Any {
        return try whichFrom(variants)
    }
    
    /// Choose The best variant.
    ///
    /// - Parameter variants: Variants to choose from.
    /// - Returns: The best variant.
    public func whichFrom<T>(_ variants: [T]) throws -> T {
        return try given(nil).whichFrom(variants)
    }
    
    /// A shorthand of decide(variants).ranked.
    public func rank<T>(_ variants: [T]) throws -> [T] {
        return try given(nil).rank(variants)
    }
    
    /// Generates all combinations of the variants from the variantMap, and chooses the best one.
    /// For example, optimize(["fontSize":[12, 13], "color":["#ffffff", "#000000"], "width": 100]) would first generate
    /// a list of variants like this:
    /// [
    ///    ["fontSize": 12, "color":"#ffffff", "width": 100],
    ///    ["fontSize": 12, "color":"#000000", "width": 100],
    ///    ["fontSize": 13, "color":"#ffffff", "width": 100],
    ///    ["fontSize": 13, "color":"#000000", "width": 100]
    /// ]
    /// and then choose one of them.
    ///
    /// - Parameter variantMap: Vaules of the variantMap are expected to be lists of JSON encodable objects. Values that
    /// are not lists are automatically wrapped as a list containing a single item.
    /// - Returns: The best variant.
    public func optimize(_ variantMap: [String : Any]) throws -> [String : Any] {
        return try given(nil).optimize(variantMap)
    }
    
    /// Generates all combinations of the variants from the variantMap, and chooses the best one.
    /// A handy alternative of optimize(variantMap) that would convert the chosen dict object to a Decodable object.
    public func optimize<T: Decodable>(_ variantMap: [String : Any], _ type: T.Type) throws -> T {
        return try given(nil).optimize(variantMap, type)
    }
    
    /// Add rewards for the most recent Decision for this model name
    ///
    /// - Parameter reward: The reward to add.
    /// - Throws: `IMPError.invalidArgument` if reward is NaN or Infinity.
    public func addReward(_ reward: Double) throws {
        if reward.isNaN || reward.isInfinite {
            throw IMPError.invalidArgument(reason: "reward can't be NaN or Infinity.")
        }
        
        guard let tracker = self.tracker else {
            throw IMPError.illegalState(reason: "trackURL can't be nil when calling addReward()")
        }
        
        try tracker.addReward(reward, forModel: modelName)
    }
    
    /// Add reward for the decision designated by the decisionId.
    ///
    /// - Parameters
    ///     - reward: The reward to add.
    ///     - decisionId: The id of a decision.
    /// - Throws: `IMPError.invalidArgument` if reward is NaN or Infinity; if decisionId is empty
    public func addReward(_ reward: Double, _ decisionId: String) throws {
        if decisionId.isEmpty {
            throw IMPError.invalidArgument(reason: "invalid decision id.")
        }
        
        guard let tracker = self.tracker else {
            throw IMPError.illegalState(reason: "trackURL can't be nil when calling addReward()")
        }
        
        try tracker.addReward(reward, forModel: modelName, decision: decisionId)
    }
}

extension DecisionModel {
    func isLoaded() -> Bool {
        return model != nil
    }
    
    private func canParseVersion(_ versionString: String?) -> Bool {
        guard let versionString = versionString else {
            return true
        }
        let array = version.components(separatedBy: ".")
        let prefix = "\(array[0])."
        return versionString.hasPrefix(prefix) || versionString == array[0]
    }
    
    public static func rank<T>(variants: [T], scores: [Double]) throws -> [T] {
        if variants.count <= 0 || scores.count <= 0 {
            throw IMPError.invalidArgument(reason: "variants and scores can't be empty")
        }
        
        if variants.count != scores.count {
            throw IMPError.invalidArgument(reason: "variants.count must equal scores.count")
        }
        
        var indices: [Int] = []
        for i in 0..<variants.count {
            indices.append(i)
        }
        
        // descending
        indices.sort { scores[$0] > scores[$1] }
        
        return indices.map { variants[$0] }
    }
}

extension DecisionModel {
    func scoreInternal<T>(_ variants: [T], _ allGivens: [String : Any]?) throws -> [Double] {
        guard !variants.isEmpty else {
            throw IMPError.emptyVariants
        }
        
        return try lockQueue.sync {
            guard let model = self.model else {
                return generateDescendingGaussians(n: UInt(variants.count))
            }
            
            guard let featureEncoder = self.featureEncoder else {
                return generateDescendingGaussians(n: UInt(variants.count))
            }
            
            let plistEncoder = PListEncoder()
            
            let encodedGivens: [String : Any]? = try allGivens.map {
                try plistEncoder.encode(AnyEncodable($0)) as! [String : Any]
            }
            
            let encodedVariants = try plistEncoder.encode(AnyEncodable(variants)) as! [Any]
            
//            let encodedFeatures = try self.featureEncoder?.encodeVariants(variants: encodedVariants, given: encodedGivens)

            // TODO: wait until FeatureEncoder is ready.
            return generateDescendingGaussians(n: UInt(variants.count))
        }
    }
}

private extension String {
    func isValidModelName() -> Bool {
        let predicate = NSPredicate(format:"SELF MATCHES %@", "^[a-zA-Z0-9][\\w\\-.]{0,63}$")
        return predicate.evaluate(with: self)
    }
}

extension DecisionModel {
    func generateDescendingGaussians(n: UInt) -> [Double] {
        var result: [Double] = []
        for _ in 0..<n {
            result.append(gaussianNumber())
        }
        return result.sorted { $0 > $1 }
    }
}

fileprivate func gaussianNumber() -> Double {
    let u1 = Double(arc4random()) / Double(UInt32.max)
    let u2 = Double(arc4random()) / Double(UInt32.max)
    let f1 = sqrt(-2 * log(u1))
    let f2 = 2 * Double.pi * u2
    return f1 * cos(f2)
}
