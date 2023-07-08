//
//  Logger.swift
//  
//
//  Created by Justin on 7/8/23.
//

import Foundation

import os.log

struct Logger {
    private static var logger = OSLog(subsystem: "ImproveAI", category: "ImproveAI")

    static func log(_ message: String) {
        #if DEBUG && IMPROVE_AI_DEBUG
        os_log("%{public}s", log: logger, type: .debug, message)
        #endif
    }
}
