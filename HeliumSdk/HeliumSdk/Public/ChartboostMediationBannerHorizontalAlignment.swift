// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The horizontal alignment of an ad within ``ChartboostMediationBannerView``.
///
/// If ``ChartboostMediationBannerView`` is made larger than the size of the displayed ad, this will be used to determine the
/// horizontal position of the ad within the view.
@objc
@frozen
public enum ChartboostMediationBannerHorizontalAlignment: Int {
    /// The ad will be displayed at the left of the view.
    case `left`

    /// The ad will be displayed at the center of the view.
    case center

    /// The ad will be displayed at the right of the view.
    case `right`
}
