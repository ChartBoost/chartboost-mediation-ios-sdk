// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A type of ``PartnerAd`` which partner banner ads should conform to.
public protocol PartnerBannerAd: PartnerAd {
    /// The partner banner ad view to display.
    var view: UIView? { get }

    /// The loaded partner ad banner size.
    var size: PartnerBannerSize? { get }
}
