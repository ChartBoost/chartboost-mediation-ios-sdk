// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A request used to load a banner ad.
@objc(CBMBannerAdLoadRequest)
public class BannerAdLoadRequest: AdLoadRequest {
    /// The maximum size of banner to request.
    ///
    /// - Note: Depending on your dashboard setup, the actual ad returned may be smaller than the requested size.
    @objc public let size: BannerSize

    /// Initializes the banner load request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter size: The maximum size of banner to request.
    @objc public init(
        placement: String,
        size: BannerSize
    ) {
        self.size = size
        super.init(placement: placement)
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? BannerAdLoadRequest else {
            return false
        }
        return placement == other.placement
            && size == other.size
    }
}
