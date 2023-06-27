//
//  ImproveAIError.swift
//  
//
//  Created by Hongxi Pan on 2022/6/24.
//

import Foundation

public enum ImproveAIError: Error {
    /// variants can't be empty
    case emptyVariants
    /// type Date, Data, URL  are not supported
    case typeNotSupported
    /// illegal arguments
    case invalidArgument(reason:String)
    /// illegal state
    case illegalState(reason:String)
    /// invalid model
    case invalidModel(reason:String)
    /// Download failure
    case downloadFailure(reason: String)
    /// internal error
    case internalError(reason: String)
}
