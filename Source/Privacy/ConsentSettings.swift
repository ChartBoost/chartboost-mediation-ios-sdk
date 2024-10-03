// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

protocol ConsentSettings: AnyObject {
    /// The delegate that receives updates whenever a consent setting changes.
    var delegate: ConsentSettingsDelegate? { get set }

    /// Current user consent info.
    var consents: [ConsentKey: ConsentValue] { get }

    /// Flag that indicates if GDPR applies based on the current IAB TCF string.
    var gdprApplies: Bool? { get }

    /// IDs of GPP Sections in force
    var gppSID: String? { get }

    /// Indicates whether the user is underage.
    var isUserUnderage: Bool { get }

    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>)

    /// Indicates that the user underage flag has changed.
    /// - parameter isUserUnderage: The new value.
    func setIsUserUnderage(_ isUserUnderage: Bool)
}

protocol ConsentSettingsDelegate: AnyObject {
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>)
    func setIsUserUnderage(_ isUserUnderage: Bool)
}

/// Stores consent settings and notifies delegate of updates.
final class ConsentSettingsManager: ConsentSettings {
    // MARK: ConsentSettings

    weak var delegate: ConsentSettingsDelegate?

    var consents: [ConsentKey: ConsentValue] {
        ChartboostCore.consent.consents
    }

    var gdprApplies: Bool? {
        // See https://github.com/InteractiveAdvertisingBureau/GDPR-Transparency-and-Consent-Framework/blob/master/TCFv2/IAB%20Tech%20Lab%20-%20CMP%20API%20v2.md#what-is-the-cmp-in-app-internal-structure-for-the-defined-api
        if let value = UserDefaults.standard.string(forKey: "IABTCF_gdprApplies") {
            return value == "1"
        } else {
            return nil
        }
    }

    var gppSID: String? {
        UserDefaults.standard.string(forKey: "IABGPP_GppSID")
    }

    var isUserUnderage: Bool {
        ChartboostCore.analyticsEnvironment.isUserUnderage
    }

    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>) {
        logger.debug("Set consents to \(consents) with modifiedKeys \(modifiedKeys)")
        delegate?.setConsents(consents, modifiedKeys: modifiedKeys)
    }

    func setIsUserUnderage(_ isUserUnderage: Bool) {
        logger.debug("Set isUserUnderage to \(isUserUnderage)")
        delegate?.setIsUserUnderage(isUserUnderage)
    }
}
