// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Delegate protocol for getting notified about FullscreenAdQueue events
@objc(ChartboostMediationFullscreenAdQueueDelegate)
public protocol FullscreenAdQueueDelegate: AnyObject {
    /// This delegate method is called when a FullscreenAdQueue completes a load request
    /// - parameter adQueue: The FullscreenAdQueue calling this method.
    /// - parameter didFinishLoadingWithResult: Ad load result with load id, metrics, and error information (if applicable).
    /// - parameter numberOfAdsReady: Current count of loaded ads in the queue.
    @objc optional
    func fullscreenAdQueue(
        _ adQueue: FullscreenAdQueue,
        didFinishLoadingWithResult: ChartboostMediationAdLoadResult,
        numberOfAdsReady: Int
    )

    /// This delegate method is called when an ad expires and is removed from the queue
    /// - parameter adQueue: The FullscreenAdQueue calling this method.
    /// - parameter numberOfAdsReady: Current count of loaded ads in the queue.
    @objc optional
    func fullscreenAdQueueDidRemoveExpiredAd(
        _ adQueue: FullscreenAdQueue,
        numberOfAdsReady: Int
    )
}
