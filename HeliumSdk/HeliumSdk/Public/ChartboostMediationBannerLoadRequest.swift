// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A request used to load a banner ad.
@objc
public class ChartboostMediationBannerLoadRequest: NSObject {
    /// Placement from the Chartboost Mediation dashboard.
    @objc public let placement: String

    /// The maximum size of banner to request.
    ///
    /// - Note: Depending on your dashboard setup, the actual ad returned may be smaller than the requested size.
    @objc public let size: ChartboostMediationBannerSize

    /// Initializes the banner load request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter size: The maximum size of banner to request.
    @objc public init(
        placement: String,
        size: ChartboostMediationBannerSize
    ) {
        self.placement = placement
        self.size = size
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ChartboostMediationBannerLoadRequest else {
            return false
        }

        return (
            placement == other.placement &&
            size == other.size
        )
    }
}
