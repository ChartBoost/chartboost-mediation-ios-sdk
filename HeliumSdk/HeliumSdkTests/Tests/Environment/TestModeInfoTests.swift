// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class TestModeInfoTests: XCTestCase {

    func testIsTestModeEnabled_notForcedOn() throws {
        Self.set_isTestModeEnabled_isForcedOn(false)

        [false, true].forEach { envValue in
            Self.setEnvironmentValue_isTestModeEnabled(envValue)
            XCTAssertEqual(TestModeInfo().isTestModeEnabled, envValue) // matches the env value
        }
    }

    func testIsTestModeEnabled_isForcedOn() throws {
        Self.set_isTestModeEnabled_isForcedOn(true)

        [false, true].forEach { envValue in
            Self.setEnvironmentValue_isTestModeEnabled(envValue)
            XCTAssert(TestModeInfo().isTestModeEnabled) // forced on
        }
    }

    /// Set the value of `CHBHTestModeHelper.isTestModeEnabled_isForcedOn` via reflection.
    private static func set_isTestModeEnabled_isForcedOn(_ value: Bool) {
        guard let testModeHelperClass: AnyClass = NSClassFromString("CHBHTestModeHelper") else {
            fatalError("cannot resolve class named CHBHTestModeHelper")
        }

        typealias Signature = @convention(c) (AnyObject, Selector, Bool) -> Void
        let selectorName = "setIsTestModeEnabled_isForcedOn:"
        let selector = Selector((selectorName))
        guard let method = class_getClassMethod(testModeHelperClass, selector) else {
            fatalError("Cannot resolve method CHBHTestModeHelper.\(selectorName)")
        }
        let implementation = method_getImplementation(method)
        let curriedImplementation: Signature = unsafeBitCast(implementation, to: Signature.self)
        curriedImplementation(testModeHelperClass, selector, value)
    }

    private static func setEnvironmentValue_isTestModeEnabled(_ enabled: Bool) {
        if enabled {
            // set environment variable
            setenv("HELIUM_TEST_MODE", "ON", 1);
        } else {
            // unset environment variable
            unsetenv("HELIUM_TEST_MODE");
        }
    }
}
