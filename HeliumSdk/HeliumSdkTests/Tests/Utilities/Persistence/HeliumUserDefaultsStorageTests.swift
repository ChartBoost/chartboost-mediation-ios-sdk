// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class HeliumUserDefaultsStorageTests: ChartboostMediationTestCase {

    lazy var userDefaults = HeliumUserDefaultsStorage(keyPrefix: "test-prefix")
    
    func test() {
        // missing keys
        XCTAssertNil(userDefaults["non_existing_key"] as String?)
        XCTAssertNil(userDefaults["non_existing_key"] as Int?)
        
        // wrong type
        userDefaults["hello"] = 123
        XCTAssertNil(userDefaults["hello"] as String?)
        XCTAssertNil(userDefaults["hello"] as Bool?)
        
        // right type
        XCTAssertEqual(userDefaults["hello"], 123)
        
        // replace
        userDefaults["hello"] = "qwerasdf"
        XCTAssertNil(userDefaults["hello"] as Int?)
        XCTAssertEqual(userDefaults["hello"], "qwerasdf")
        
        // new key
        userDefaults["hello_2"] = 123
        XCTAssertEqual(userDefaults["hello_2"], 123)
        XCTAssertEqual(userDefaults["hello"], "qwerasdf")
    }
}
