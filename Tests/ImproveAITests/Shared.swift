//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/12/16.
//

import Foundation
import ImproveAI

let defaultTrackURL = URL(string: "https://gh8hd0ee47.execute-api.us-east-1.amazonaws.com/track")!

let defaultTrackApiKey = "api-key"

let zippedModelURL = URL(string: "https://improveai-mindblown-mindful-prod-models.s3.amazonaws.com/models/latest/messages-2.0.mlmodel.gz")!

let plainModelURL = URL(string: "https://improveai-mindblown-mindful-dev-models.s3.amazonaws.com/deleteme/messages-v7.mlmodel")!

func model() -> DecisionModel {
    return try! DecisionModel(modelName: "greetings")
}

func loadedModel() -> DecisionModel {
    return try! model().load(zippedModelURL)
}
