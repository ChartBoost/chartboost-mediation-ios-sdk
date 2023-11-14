// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class UserDefaultsStorageMock: UserDefaultsStorage {
    
    var values: [String: Any] = [:]
    
    subscript<Value>(key: String) -> Value? {
        get { values[key] as? Value }
        set { values[key] = newValue }
    }
}
