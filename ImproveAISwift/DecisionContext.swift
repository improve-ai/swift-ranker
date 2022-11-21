////
////  File.swift
////  
////
////  Created by Hongxi Pan on 2022/6/12.
////
//
//import ImproveAICore
//
//public struct DecisionContext {
////    internal var decisionContext: IMPDecisionContext
////    
////    internal var decisionModel: DecisionModel
////    
////    internal let givens: [String : Any]?
////    
////    internal init(decisionContext: IMPDecisionContext, decisionModel: DecisionModel, givens: [String : Any]?) {
////        self.decisionContext = decisionContext
////        self.decisionModel = decisionModel
////        self.givens = givens
////    }
////    
////    public func score<T>(_ variants: [T]) throws -> [Double] {
////        if variants.isEmpty {
////            throw IMPError.emptyVariants
////        }
////        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
////        return self.decisionContext.score(encodedVariants).map{ $0.doubleValue }
////    }
////    
////    public func decide<T>(_ variants: [T], _ ordered: Bool = false) throws -> Decision<T> {
////        if variants.isEmpty {
////            throw IMPError.emptyVariants
////        }
////        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
////        return Decision(self.decisionContext.decide(encodedVariants, ordered), variants)
////    }
////    
////    public func decide<T>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
////        if (variants.isEmpty || scores.isEmpty) {
////            throw IMPError.invalidArgument(reason: "variants and scores can't be empty.")
////        }
////        
////        if variants.count != scores.count {
////            throw IMPError.invalidArgument(reason: "variants.count must be equal to scores.count.")
////        }
////        
////        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
////        return Decision(self.decisionContext.decide(encodedVariants, scores.map{ NSNumber(value: $0) }), variants)
////    }
////    
////    public func which(_ variants: Any...) throws -> Any {
////        return try whichFrom(variants)
////    }
////    
////    public func which<T>(_ variants: T...) throws -> T {
////        return try whichFrom(variants)
////    }
////    
////    public func whichFrom<T>(_ variants: [T]) throws -> T {
////        let decision = try decide(variants)
////        
////        let selector = NSSelectorFromString("trackSilently")
////        decision.decision.perform(selector)
////        
////        return decision.best
////    }
////    
////    public func rank<T>(_ variants: [T]) throws -> [T] {
////        if variants.isEmpty {
////            throw IMPError.emptyVariants
////        }
////        return try decide(variants).ranked
////    }
////    
////    public func optimize(_ variantMap: [String : Any]) throws -> [String : Any] {
////        return try whichFrom(DecisionModel.fullFactorialVariants(variantMap))
////    }
////    
////    public func optimize<T: Decodable>(_ variantMap: [String : Any], _ type: T.Type) throws -> T {
////        let dict = try optimize(variantMap)
////        let data = try JSONEncoder().encode(AnyEncodable(dict))
////        return try JSONDecoder().decode(type, from: data)
////    }
////    
////    // MARK: Deprecated, remove in 8.0
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func chooseFrom<T>(_ variants: [T]) throws -> Decision<T> {
////        return try decide(variants)
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func chooseFrom<T>(_ variants: [T], _ scores: [Double]) throws -> Decision<T> {
////        return try decide(variants, scores)
////    }
////
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func chooseFirst<T>(_ variants: [T]) throws -> Decision<T> {
////        if variants.isEmpty {
////            throw IMPError.emptyVariants
////        }
////        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
////        return Decision(self.decisionContext.chooseFirst(encodedVariants), variants)
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func first<T>(_ variants: [T]) throws -> T {
////        return try chooseFirst(variants).get()
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func first<T>(_ variants: T...) throws -> T {
////        return try chooseFirst(variants).get()
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func first(_ variants: Any...) throws -> Any {
////        return try chooseFirst(variants).get()
////    }
////
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func chooseRandom<T>(_ variants: [T]) throws -> Decision<T> {
////        if variants.isEmpty {
////            throw IMPError.emptyVariants
////        }
////        let encodedVariants = try PListEncoder().encode(variants.map{ AnyEncodable($0) }) as! [Any]
////        return Decision(self.decisionContext.chooseRandom(encodedVariants), variants)
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func random<T>(_ variants: [T]) throws -> T {
////        return try chooseRandom(variants).get()
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func random<T>(_ variants: T...) throws -> T {
////        return try chooseRandom(variants).get()
////    }
////    
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func random(_ variants: Any...) throws -> Any {
////        return try chooseRandom(variants).get()
////    }
////        
////    @available(*, deprecated, message: "Remove in 8.0")
////    public func chooseMultivariate(_ variants: [String : Any]) throws -> Decision<[String: Any]> {
////        return try decide(DecisionModel.fullFactorialVariants(variants))
////    }
//}
