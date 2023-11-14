// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The type of a banner ad.
@objc
public enum ChartboostMediationBannerType: Int {

    /// The banner ad is a fixed size, and will not change when the size of the containing
    /// ``ChartboostMediationBannerView`` changes.
    case fixed

    /// The banner is an adaptive size, and will resize to fit when the size of the containing
    /// ``ChartboostMediationBannerView`` changes.
    case adaptive
}
