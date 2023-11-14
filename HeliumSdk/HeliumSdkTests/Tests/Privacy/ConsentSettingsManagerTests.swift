// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class ConsentSettingsManagerTests: ChartboostMediationTestCase {

    lazy var manager = ConsentSettingsManager()
    let userDefaults = UserDefaults.standard
    let tcStringKey = "IABTCF_TCString"
    
    override func setUp() {
        super.setUp()
        
        manager.delegate = mocks.consentSettingsDelegate
        userDefaults.removeObject(forKey: "tcStringKey")
    }

    override func tearDown() {
        super.tearDown()
        userDefaults.removeObject(forKey: "tcStringKey")
    }
    
    func testIsSubjectToGDPR() {
        // Default value
        mocks.userDefaultsStorage.values["gdpr"] = nil
        XCTAssertEqual(manager.isSubjectToGDPR, nil)
        
        // Set to true
        manager.isSubjectToGDPR = true
        XCTAssertEqual(mocks.userDefaultsStorage.values["gdpr"] as? Bool, true)
        XCTAssertEqual(manager.isSubjectToGDPR, true)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR)
        
        // Set to false
        manager.isSubjectToGDPR = false
        XCTAssertEqual(mocks.userDefaultsStorage.values["gdpr"] as? Bool, false)
        XCTAssertEqual(manager.isSubjectToGDPR, false)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR)
    }
    
    func testGDPRConsent() {
        // Default value
        mocks.userDefaultsStorage.values["gdprconsent"] = nil
        XCTAssertEqual(manager.gdprConsent, .unknown)
        
        // Set to granted
        manager.gdprConsent = .granted
        XCTAssertEqual(mocks.userDefaultsStorage.values["gdprconsent"] as? Bool, true)
        XCTAssertEqual(manager.gdprConsent, .granted)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR)
        
        // Set to denied
        manager.gdprConsent = .denied
        XCTAssertEqual(mocks.userDefaultsStorage.values["gdprconsent"] as? Bool, false)
        XCTAssertEqual(manager.gdprConsent, .denied)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR)
    }
    
    func testIsSubjectToCOPPA() {
        // Default value
        mocks.userDefaultsStorage.values["coppa"] = nil
        XCTAssertEqual(manager.isSubjectToCOPPA, nil)
        
        // Set to true
        manager.isSubjectToCOPPA = true
        XCTAssertEqual(mocks.userDefaultsStorage.values["coppa"] as? Bool, true)
        XCTAssertEqual(manager.isSubjectToCOPPA, true)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeCOPPA)
        
        // Set to false
        manager.isSubjectToCOPPA = false
        XCTAssertEqual(mocks.userDefaultsStorage.values["coppa"] as? Bool, false)
        XCTAssertEqual(manager.isSubjectToCOPPA, false)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeCOPPA)
    }
    
    func testCCPAConsent() {
        // Default value
        mocks.userDefaultsStorage.values["ccpa"] = nil
        XCTAssertEqual(manager.ccpaConsent, nil)
        XCTAssertEqual(manager.ccpaPrivacyString, nil)
        
        // Set to true
        manager.ccpaConsent = true
        XCTAssertEqual(mocks.userDefaultsStorage.values["ccpa"] as? Bool, true)
        XCTAssertEqual(manager.ccpaConsent, true)
        XCTAssertEqual(manager.ccpaPrivacyString, "1YN-")
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeCCPA)
        
        // Set to false
        manager.ccpaConsent = false
        XCTAssertEqual(mocks.userDefaultsStorage.values["ccpa"] as? Bool, false)
        XCTAssertEqual(manager.ccpaConsent, false)
        XCTAssertEqual(manager.ccpaPrivacyString, "1YY-")
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeCCPA)
    }

    func testGdprTCString() {
        XCTAssertNil(manager.gdprTCString)

        let randomString = String.random(length: 20)
        userDefaults.set(randomString, forKey: tcStringKey)

        XCTAssertEqual(randomString, manager.gdprTCString)

        userDefaults.set(nil, forKey: tcStringKey)
        XCTAssertNil(manager.gdprTCString)
    }

    func testCCPAPrivacyStringForCCPAConsent() {
        XCTAssertEqual(manager.ccpaPrivacyString(forCCPAConsent: true), "1YN-")
        XCTAssertEqual(manager.ccpaPrivacyString(forCCPAConsent: false), "1YY-")
    }

    func testPartnerConsents() {
        // Default value
        mocks.userDefaultsStorage.values["partnerConsents"] = nil
        XCTAssertAnyEqual(manager.partnerConsents, [:])

        // Set to some value
        var expectedValue = ["partnerID 1": true, "partnerID 2": false]
        manager.partnerConsents = expectedValue
        XCTAssertAnyEqual(mocks.userDefaultsStorage.values["partnerConsents"] as? [String: Bool], expectedValue)
        XCTAssertAnyEqual(manager.partnerConsents, expectedValue)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR, .didChangeCCPA)

        // Update existing value
        manager.partnerConsents["partnerID 2"] = true
        expectedValue = ["partnerID 1": true, "partnerID 2": true]
        XCTAssertAnyEqual(mocks.userDefaultsStorage.values["partnerConsents"] as? [String: Bool], expectedValue)
        XCTAssertAnyEqual(manager.partnerConsents, expectedValue)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR, .didChangeCCPA)

        // Add new value
        manager.partnerConsents["partnerID 3"] = false
        expectedValue = ["partnerID 1": true, "partnerID 2": true, "partnerID 3": false]
        XCTAssertAnyEqual(mocks.userDefaultsStorage.values["partnerConsents"] as? [String: Bool], expectedValue)
        XCTAssertAnyEqual(manager.partnerConsents, expectedValue)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR, .didChangeCCPA)

        // Remove value
        manager.partnerConsents["partnerID 1"] = nil
        expectedValue = ["partnerID 2": true, "partnerID 3": false]
        XCTAssertAnyEqual(mocks.userDefaultsStorage.values["partnerConsents"] as? [String: Bool], expectedValue)
        XCTAssertAnyEqual(manager.partnerConsents, expectedValue)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR, .didChangeCCPA)

        // Remove all values
        manager.partnerConsents = [:]
        expectedValue = [:]
        XCTAssertAnyEqual(mocks.userDefaultsStorage.values["partnerConsents"] as? [String: Bool], expectedValue)
        XCTAssertAnyEqual(manager.partnerConsents, expectedValue)
        XCTAssertMethodCalls(mocks.consentSettingsDelegate, .didChangeGDPR, .didChangeCCPA)
    }
}
