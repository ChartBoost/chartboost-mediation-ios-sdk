// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
import ChartboostCoreSDK
@testable import ChartboostMediationSDK

// Since we compare against optional Bools, it's easier to use
// XCTAssertEqual(value, true)
// than
// let value = try XCTUnwrap(optionalValue)
// XCTAssertTrue(value)
// swiftlint:disable xct_specific_matcher
class ConsentSettingsManagerTests: ChartboostMediationTestCase {

    lazy var manager = ConsentSettingsManager()

    override func setUp() {
        super.setUp()
        
        manager.delegate = mocks.consentSettingsDelegate
    }

    func testConsents() {
        XCTAssertEqual(manager.consents, ChartboostCore.consent.consents)
    }

    func testGDPRApplies() {
        UserDefaults.standard.set(nil, forKey: "IABTCF_gdprApplies")
        XCTAssertNil(manager.gdprApplies)

        UserDefaults.standard.set("1", forKey: "IABTCF_gdprApplies")
        XCTAssertEqual(manager.gdprApplies, true)

        UserDefaults.standard.set("0", forKey: "IABTCF_gdprApplies")
        XCTAssertEqual(manager.gdprApplies, false)
    }

    func testIsUserUnderage() {
        XCTAssertEqual(manager.isUserUnderage, ChartboostCore.analyticsEnvironment.isUserUnderage)
    }

    func testSetConsents() {
        manager.delegate = mocks.consentSettingsDelegate
        manager.setConsents(["k1": "v1", "k2": "v2", "k3": "v3"], modifiedKeys: ["k1", "k2"])

        XCTAssertMethodCalls(
            mocks.consentSettingsDelegate,
            .setConsents,
            parameters: [["k1": "v1", "k2": "v2", "k3": "v3"], Set(["k1", "k2"])]
        )
    }

    func testSetIsUserUnderage() {
        manager.delegate = mocks.consentSettingsDelegate
        manager.setIsUserUnderage(true)

        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .setIsUserUnderage, parameters: [true])
    }
}
// swiftlint:enable xct_specific_matcher
