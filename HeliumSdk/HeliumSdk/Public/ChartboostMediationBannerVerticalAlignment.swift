// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// The vertical alignment of an ad within ``ChartboostMediationBannerView``.
///
/// If ``ChartboostMediationBannerView`` is made larger than the size of the displayed ad, this will be used to determine the
/// vertical position of the ad within the view.
@objc
@frozen
public enum ChartboostMediationBannerVerticalAlignment: Int {
    /// The ad will be displayed at the top of the view.
    case top

    /// The ad will be displayed at the center of the view.
    case center

    /// The ad will be displayed at the bottom of the view.
    case bottom
}
