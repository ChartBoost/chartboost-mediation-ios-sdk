// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A request used to load a Chartboost Mediation fullscreen ad.
@objc(CBMFullscreenAdLoadRequest)
public class FullscreenAdLoadRequest: AdLoadRequest {
    /// Key-value pairs to be associated with the placement.
    ///
    /// Keys are limited to 64 characters and values are limited to 256 characters.
    @objc public let keywords: [String: String]

    /// Local extras which should be passed to adapter calls and merged with the backend extras.
    @objc public let partnerSettings: [String: Any]

    /// UUID Identifying the queue (if any) that initiated this load request.
    let queueID: String?

    /// Initializes the request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter keywords: Key-value pairs to be associated with the placement.
    /// Note the character limits indicated in ``keywords``.
    /// - parameter partnerSettings: Local extras which should be passed to adapter calls and merged with the backend extras.
    @objc public convenience init(placement: String, keywords: [String: String] = [:], partnerSettings: [String: Any]?) {
        self.init(placement: placement, keywords: keywords, partnerSettings: partnerSettings, queueID: nil)
    }

    /// Initializes the request with the desired parameters.
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter keywords: Key-value pairs to be associated with the placement.
    /// Note the character limits indicated in ``keywords``.
    @objc public convenience init(placement: String, keywords: [String: String] = [:]) {
        self.init(placement: placement, keywords: keywords, partnerSettings: nil, queueID: nil)
    }

    /// Private initializer for requests originiating from FullscreenAdQueues
    /// - parameter placement: Placement from the Chartboost Mediation dashboard.
    /// - parameter keywords: Key-value pairs to be associated with the placement.
    /// - parameter queueID: ID of the queue that initiated this load request,
    init(placement: String, keywords: [String: String] = [:], partnerSettings: [String: Any]?, queueID: String?) {
        self.keywords = keywords
        self.queueID = queueID
        self.partnerSettings = partnerSettings ?? [:]
        super.init(placement: placement)
    }
}
