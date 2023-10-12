// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class UserSettingsProviderTests: HeliumTestCase {
    func testInputLanguagesConcurrency() {
        let userSettingsProvider = UserSettingsProvider()
        let expectation = self.expectation(description: "testInputLanguagesConcurrency")
        expectation.expectedFulfillmentCount = 3

        DispatchQueue.main.async {
            let inputLanguages = userSettingsProvider.inputLanguages
            if #available(iOS 17.0, *) {
                XCTAssert(inputLanguages.isEmpty)
            } else {
                XCTAssertFalse(inputLanguages.isEmpty)
            }
            expectation.fulfill()
        }
        DispatchQueue.global(qos: .default).async {
            let inputLanguages = userSettingsProvider.inputLanguages
            if #available(iOS 17.0, *) {
                XCTAssert(inputLanguages.isEmpty)
            } else {
                XCTAssertFalse(inputLanguages.isEmpty)
            }
            expectation.fulfill()
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let inputLanguages = userSettingsProvider.inputLanguages
            if #available(iOS 17.0, *) {
                XCTAssert(inputLanguages.isEmpty)
            } else {
                XCTAssertFalse(inputLanguages.isEmpty)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    func testPrivacyBanList() {
        let userSettingsProvider = UserSettingsProvider()

        if #available(iOS 17.0, *) {
            mocks.privacyConfigurationDependency.privacyBanList = [.languageAndLocale]
            XCTAssertNil(userSettingsProvider.languageCode)

            mocks.privacyConfigurationDependency.privacyBanList = []
            XCTAssertEqual(userSettingsProvider.languageCode, "en")
        } else {
            mocks.privacyConfigurationDependency.privacyBanList = [.languageAndLocale]
            XCTAssertEqual(userSettingsProvider.languageCode, "en")

            mocks.privacyConfigurationDependency.privacyBanList = []
            XCTAssertEqual(userSettingsProvider.languageCode, "en")
        }
    }
}
