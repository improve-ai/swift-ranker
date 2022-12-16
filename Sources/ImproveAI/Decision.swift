//
//  Decision.swift
//  
//
//  Created by Hongxi Pan on 2022/12/13.
//

import Foundation

public struct Decision<T> {
    
    /// The id that uniquely identifies the decision after it's been tracked. It's nil until the decision
    /// is tracked by calling track().
    public var id: String?
    
    /// The ranked variants.
    public let ranked: [T]
    
    /// Additional context info that was used along with each of the variants to score them, including the givens
    /// passed by DecisionModel.given() and givens that was provided by the givensProvider. The givens here
    /// would also be included in tracking.
    public let givens: [String : Any]?
    
    /// The best variant.
    public var best: T {
        return ranked[0]
    }
    
    private let decisionModel: DecisionModel
    
    private lazy var lockQueue = DispatchQueue(label: "DecisionModel.lockQueue")
    
    init(model: DecisionModel, ranked: [T], givens: [String : Any]?) {
        self.decisionModel = model
        self.ranked = ranked
        self.givens = givens
    }
    
    /// Tracks the decision.
    /// - Returns: The id that uniquely identifies the tracked decision.
    public mutating func track() throws -> String {
        try lockQueue.sync {
            if self.id != nil {
                throw IMPError.illegalState(reason: "the decision is already tracked!")
            }
            
            guard let tracker = self.decisionModel.tracker else {
                throw IMPError.illegalState(reason: "trackURL of the underlying DecisionModel is nil!")
            }
            
            id = try tracker.track(rankedVariants: ranked, given: givens, modelName: decisionModel.modelName)
            
            return id!
        }
    }
    
    /// Adds rewards that only apply to this specific decision. Before calling this method, make sure that the decision is
    /// already tracked by calling track().
    ///
    /// - Parameter reward: The reward to add. Must not be NaN, or Infinity.
    /// - Throws: `IMPError.invalidArgument` if reward is NaN or infinity.
    /// - Throws: `IMPError.illegalState` if the the decision is not tracked yet.
    public func addReward(_ reward: Double) throws {
        guard let id = self.id else {
            throw IMPError.illegalState(reason: "the decision has not been tracked yet!")
        }
        try self.decisionModel.addReward(reward, id)
    }
}

extension Decision {
    func trackSilently() {
        if let tracker = self.decisionModel.tracker {
            _ = try? tracker.track(rankedVariants: ranked, given: givens, modelName: decisionModel.modelName)
        }
    }
}
