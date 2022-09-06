//
//  File.swift
//  
//
//  Created by Hongxi Pan on 2022/6/24.
//

import Foundation

public enum IMPError: Error {
    /// variants can't be empty
    case emptyVariants
    /// type Date, Data, URL  are not supported
    case typeNotSupported
    /// illegal arguments
    case invalidArgument(reason:String)
}
