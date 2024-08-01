// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Internal ad format model.
/// Enum case values match those expected to be sent/received by backend.
enum AdFormat: String, CaseIterable {
    case adaptiveBanner = "adaptive_banner"                 // snake-case for compatibility with backend
    case banner
    case interstitial
    case rewarded
    case rewardedInterstitial = "rewarded_interstitial"     // snake-case for compatibility with backend
}

extension AdFormat {
    /// Returns `true` if this is `adaptiveBanner` or `banner`, or false if it's a fullscreen ad.
    var isBanner: Bool {
        // An exhaustive switch makes sure that we don't forget to handle new format cases
        switch self {
        case .interstitial, .rewarded, .rewardedInterstitial:
            return false
        case .banner, .adaptiveBanner:
            return true
        }
    }

    /// Returns `true` if this is a fullscreen ad, like `interstitial` or `rewarded`.
    var isFullscreen: Bool {
        !isBanner
    }

    /// Convenience constructor to convert an internal ``AdFormat`` into a ``PartnerAdFormat``.
    var partnerAdFormat: PartnerAdFormat {
        switch self {
        case .banner, .interstitial, .rewarded, .rewardedInterstitial:
            rawValue
        case .adaptiveBanner:
            // Both banner and adaptive_banner are considered `PartnerAdFormats.banner` for adapter purposes.
            // We keep them separate internally because that's how our backend organizes them, but in practice
            // partner adapters don't need this distinction on an ad format level. 
            // Info about the banner type and size is already provided to them in the `BannerSize` model included
            // in prebid and load requests.
            Self.banner.rawValue
        }
    }
}
