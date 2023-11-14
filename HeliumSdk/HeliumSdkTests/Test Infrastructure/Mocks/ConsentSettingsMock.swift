// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ConsentSettingsMock: ConsentSettings {
    
    var delegate: ConsentSettingsDelegate?
    
    var isSubjectToCOPPA: Bool?
    
    var isSubjectToGDPR: Bool?
    
    var gdprConsent: GDPRConsentStatus = .unknown
    
    var ccpaConsent: Bool?
    
    var ccpaPrivacyString: String?

    var gdprTCString: String?

    var partnerConsents: [PartnerIdentifier : Bool] = [:]
}

extension ConsentSettingsMock {
    
    func randomizeAll() {
        isSubjectToCOPPA = Bool.random() ? Bool.random() : nil
        isSubjectToGDPR = Bool.random() ? Bool.random() : nil
        gdprConsent = Bool.random() ? (Bool.random() ? .granted : .denied) : .unknown
        ccpaConsent = Bool.random() ? Bool.random() : nil
        ccpaPrivacyString = ccpaConsent == true ? "1YN-" : (ccpaConsent == false ? "1YY-" : nil)
        gdprTCString = Bool.random() ? String.random(length: Int.random(in: 10...20)) : nil
    }
}

extension String {
    static func random(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
