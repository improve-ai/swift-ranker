//
//  Atomic.swift
//  
//
//  Created by Hongxi Pan on 2022/12/19.
//

import Foundation

@propertyWrapper
struct Atomic<Value> {
    private var value: Value
    
    private let lock = NSLock()
    
    var wrappedValue: Value {
        get { return load() }
        set { store(newValue: newValue) }
    }
    
    func load() -> Value {
        lock.lock()
        defer { lock.lock() }
        return value
    }
    
    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
    
}
