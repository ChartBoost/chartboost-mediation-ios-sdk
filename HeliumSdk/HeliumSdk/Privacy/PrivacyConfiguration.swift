// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Privacy related configuration
protocol PrivacyConfiguration {
    /// A list of iOS APIs that Apple might add to the list of Required Reason API and the SDK needs to stop using.
    /// - This is a runtime workaround that might not pass static analysis during app submission review, but at the
    /// minimum app developers has something to appeal against the App Store rejection with this implementation in place.
    /// - Apple doc: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
    var privacyBanList: [PrivacyBanListCandidate] { get }
}

enum PrivacyBanListCandidate: String, Codable, CaseIterable {
    /// Related iOS API: `Locale.current.language.languageCode`
    case languageAndLocale = "language_and_locale"

    /// Related iOS API: `sysctlbyname()`
    case sysctl = "sysctl"

    /// Related iOS API: `NSTimeZone.local.secondsFromGMT(for:)`
    case timeZone = "time_zone"
}
