// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A type of ``PartnerAd`` which partner fullscreen ads should conform to.
public protocol PartnerFullscreenAd: PartnerAd {
    /// Shows a loaded ad.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter viewController: The view controller on which the ad will be presented on.
    /// - parameter completion: Closure to be performed once the ad has been shown.
    func show(
        with viewController: UIViewController,
        completion: @escaping (Error?) -> Void
    )
}
