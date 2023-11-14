// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides read and write capabilities to the standard User Defaults.
protocol UserDefaultsStorage: AnyObject {
    subscript<Value>(_ key: String) -> Value? { get set }
}

/// A UserDefaultsStorage implementation namespaces keys to group all Helium-related values together.
final class HeliumUserDefaultsStorage: UserDefaultsStorage {
    
    let keyPrefix: String
    
    private let defaults = UserDefaults.standard
    
    private func prefixedKey(_ key: String) -> String {
        keyPrefix + key
    }
    
    init(keyPrefix: String) {
        self.keyPrefix = keyPrefix
    }
    
    subscript<Value>(key: String) -> Value? {
        get {
            defaults.object(forKey: prefixedKey(key)) as? Value
        }
        set {
            defaults.set(newValue, forKey: prefixedKey(key))
        }
    }
}
