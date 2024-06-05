// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A request used to load a Chartboost Mediation ad.
@objc
public class ChartboostMediationAdLoadRequest: NSObject {
    /// Placement from the Chartboost Mediation dashboard.
    @objc public let placement: String

    /// Key-value pairs to be associated with the placement.
    /// 
    /// Keys are limited to 64 characters and values are limited to 256 characters.
    @objc public let keywords: [String: String]

    /// UUID Identifying the queue (if any) that initiated this load request.
    internal let queueID: String?

    /// Initializes the request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter keywords: Key-value pairs to be associated with the placement.
    /// Note the character limits indicated in ``keywords``.
    @objc public init(placement: String, keywords: [String: String] = [:]) {
        self.placement = placement
        self.keywords = keywords
        self.queueID = nil
    }

    /// Private initializer for requests originiating from FullscreenAdQueues
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter keywords: Key-value pairs to be associated with the placement.
    /// - parameter queueID: ID of the queue that initiated this load request,
    internal init(placement: String, keywords: [String: String] = [:], queueID: String) {
        self.placement = placement
        self.keywords = keywords
        self.queueID = queueID
    }
}
