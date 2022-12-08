//
//  AppGivensProvider.swift
//  
//
//  Created by Hongxi Pan on 2022/12/7.
//

import UIKit
import Foundation
import CoreTelephony

struct GivensKey {
    static let context = "context"
    static let country = "country"
    static let lang = "lang"
    static let tz = "tz"
    static let carrier = "carrier"
    static let device = "device"
    static let os = "os"
    static let pixels = "pixels"
    static let app = "app"
    static let weekday = "weekday"
    static let time = "time"
    static let runtime = "runtime"
    static let day = "day"
    static let decisionNumberOfModel = "d"
    static let rewardsOfModel = "r"
    static let rewardPerDecision = "r/d"
    static let decisionsPerDay = "d/day"
}

public struct AppGivensProvider : GivensProvider {
    
    public static let shared = AppGivensProvider()
    
    public func givensForModel(decisionModel: DecisionModel, givens: Any?) -> [String : Any] {
        var result: [String : Any] = [:]
        
        result[GivensKey.context] = givens
        result[GivensKey.country] = country()
        result[GivensKey.lang] = language()
        result[GivensKey.tz] = timezone()
        result[GivensKey.carrier] = carrier()
        result[GivensKey.device] = deviceIdentifier()
        result[GivensKey.os] = os()
        result[GivensKey.pixels] = pixels()
        result[GivensKey.app] = app()
        result[GivensKey.weekday] = weekday().toDecimal()
        result[GivensKey.time] = fractionalDay().toDecimal()
        
        return result
    }
}



extension AppGivensProvider {
    // two letter code (AU)
    func country() -> String? {
        return Locale.current.regionCode?.uppercased()
    }
    
    // two letter code (EN)
    func language() -> String? {
        return Locale.current.languageCode?.uppercased()
    }
    
    // numeric GMT offset
    func timezone() -> Int {
        return TimeZone.current.secondsFromGMT() / 3600
    }
    
    // cell network
    func carrier() -> String? {
        let info = CTTelephonyNetworkInfo()
        if let carriers = info.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                if let carrierName = carrier.carrierName, !carrierName.isEmpty {
                    return carrierName
                }
            }
        }
        return nil
    }
    
    // device model including version (iPad11,6)
    func deviceIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
    
    // os including version (iOS 16.0.2)
    func os() -> String {
        let systemVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(systemVersion.majorVersion).\(systemVersion.minorVersion).\(systemVersion.patchVersion)"
    }
    
    // screen width x screen height
    func pixels() -> Int {
        let scale = UIScreen.main.scale
        let rect = UIScreen.main.bounds
        return Int(rect.size.width * scale * rect.size.height * scale)
    }
    
    // app name and version (#Mindful 6.1.1)
    func app() -> String? {
        let bundle = Bundle.main
        let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "")
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        return "\(appName) \(appVersion)"
    }
    
    // (ISO 8601, monday==1.0, sunday==7.0) plus fractional part of day
    func weekday() -> Double {
        let now = Date()
        let calendar = Calendar(identifier: .iso8601)
        let weekday = calendar.ordinality(of: .weekday, in: .weekOfMonth, for: now)!
        return Double(weekday) + fractionalDay()
    }
    
    // fractional day since midnight
    func fractionalDay() -> Double {
        let now = Date()
        let calendar = Calendar(identifier: .iso8601)
        let midnight = calendar.startOfDay(for: now)
        let second = calendar.dateComponents([.second], from: midnight, to: now).second!
        return Double(second) / 86400
    }
}

extension Double {
    func toDecimal() -> NSDecimalNumber {
        return NSDecimalNumber(string: String(format: "%.6lf", self))
    }
}
