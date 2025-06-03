// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The type of a banner ad.
@objc(CBMBannerType)
public enum BannerType: Int, Equatable {
    /// The banner ad is a fixed size, and will not change when the size of the containing
    /// ``BannerAdView`` changes.
    case fixed

    /// The banner is an adaptive size, and will resize to fit when the size of the containing
    /// ``BannerAdView`` changes.
    case adaptive
}
