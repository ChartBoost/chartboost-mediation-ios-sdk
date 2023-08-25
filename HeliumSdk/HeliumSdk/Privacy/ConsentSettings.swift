// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol ConsentSettings: AnyObject {
    /// The delegate that receives updates whenever a consent setting changes.
    var delegate: ConsentSettingsDelegate? { get set }
    
    /// Indicates of user is subject to COPPA (true if YES).  If the value is nil, then the value has not been set, perhaps
    /// because it has not yet been determined.
    var isSubjectToCOPPA: Bool? { get set }
    
    /// Indicates if the user is subject to GDPR consent (true if YES). If the value is nil, then that value has not been set,
    /// perhaps because it has not yet been determined or even possibly because they aren't subjecet to GDPR.
    var isSubjectToGDPR: Bool? { get set }
    
    /// Indicates if the user has given consent under GDPR.
    var gdprConsent: GDPRConsentStatus { get set }
    
    /// Indicates if the user has given consent under CCPA.  If the value is nil, then that vlaue has not been set,
    /// perhaps because it has not yet been determined or because they are not subject to CCPA at all.
    var ccpaConsent: Bool? { get set }
    
    /// The CCPA consent formatted as a IAB's US Privacy String.
    var ccpaPrivacyString: String? { get }

    /// The GDPR TCFv2 value.
    /// https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework
    var gdprTCString: String? { get }
}

protocol ConsentSettingsDelegate: AnyObject {
    func didChangeGDPR()
    func didChangeCOPPA()
    func didChangeCCPA()
}

/// Stores consent settings and notifies delegate of updates.
final class ConsentSettingsManager: ConsentSettings {
    
    /// User defaults keys
    private enum Keys {
        static let ccpa = "ccpa"
        static let coppa = "coppa"
        static let gdpr = "gdpr"
        static let gdprConsent = "gdprconsent"
        static let tcString = "IABTCF_TCString"
    }
    
    /// Constants for IAB's US Privacy String to indicate conformance to CCPA laws.
    /// See https://github.com/InteractiveAdvertisingBureau/USPrivacy/blob/master/CCPA/US%20Privacy%20String.md
    private enum USPrivacyString {
        static let optIn = "1YN-"
        static let optOut = "1YY-"
    }
    
    // We use a cbUserDefaultsStorage instead of the standard userDefaultsStorage for compatibility with previous versions
    // that for some reason stored consent values using a different key prefix.
    @Injected(\.cbUserDefaultsStorage) private var userDefaults

    // UserDefaults.standard is used to get the GDPR TCFv2 value keyed directly by `IABTCF_TCString` with no
    // other key prefix.
    private let standardUserDefaults = UserDefaults.standard
    
    // MARK: ConsentSettings
    
    weak var delegate: ConsentSettingsDelegate?
    
    var isSubjectToGDPR: Bool? {
        get {
            userDefaults[Keys.gdpr]
        }
        set {
            logger.debug("Set subject to GDPR to \(newValue?.description ?? "nil")")
            userDefaults[Keys.gdpr] = newValue
            delegate?.didChangeGDPR()
        }
    }
    
    var gdprConsent: GDPRConsentStatus {
        get {
            GDPRConsentStatus(value: userDefaults[Keys.gdprConsent])
        }
        set {
            logger.debug("Set GDPR consent to \(newValue)")
            userDefaults[Keys.gdprConsent] = newValue.boolValue
            delegate?.didChangeGDPR()
        }
    }
    
    var isSubjectToCOPPA: Bool? {
        get {
            userDefaults[Keys.coppa]
        }
        set {
            logger.debug("Set subject to COPPA to \(newValue?.description ?? "nil")")
            userDefaults[Keys.coppa] = newValue
            delegate?.didChangeCOPPA()
        }
    }
    
    var ccpaConsent: Bool? {
        get {
            userDefaults[Keys.ccpa]
        }
        set {
            logger.debug("Set CCPA consent to \(newValue?.description ?? "nil")")
            userDefaults[Keys.ccpa] = newValue
            delegate?.didChangeCCPA()
        }
    }
    
    var ccpaPrivacyString: String? {
        // HE SDK does not provide a public API to set a custom privacy string yet, so infer it from the boolean consent
        switch ccpaConsent {
        case true?: return USPrivacyString.optIn
        case false?: return USPrivacyString.optOut
        case nil: return nil
        }
    }

    /// See https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20CMP%20API%20v2.md
    /// and search for `IABTCF_TCString`, `iOS` and `NSUserDefaults` to find relevant information.
    var gdprTCString: String? {
        guard let tcString = standardUserDefaults.string(forKey: Keys.tcString), !tcString.isEmpty else {
            return nil
        }
        return tcString
    }
}

// MARK: - Helpers

private extension GDPRConsentStatus {
    
    init(value: Bool?) {
        switch value {
        case true?: self = .granted
        case false?: self = .denied
        case nil: self = .unknown
        }
    }
    
    var boolValue: Bool? {
        switch self {
        case .granted: return true
        case .denied: return false
        case .unknown: return nil
        }
    }
}
