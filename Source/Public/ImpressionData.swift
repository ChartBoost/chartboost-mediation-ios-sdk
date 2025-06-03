// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Impression Level Revenue Data (ILRD) object that will be contained in the `NSNotification.object` field for
/// `Notification.Name.chartboostMediationDidReceiveILRD` notifications.
@objc(CBMImpressionData)
public class ImpressionData: NSObject {
    /// The placement associated with Impression Level Revenue Data.
    @objc public let placement: String

    /// The Impression Level Revenue Data JSON.
    @objc public let jsonData: [String: Any]

    /// Initializes an ILRD object.
    /// - parameter placement: The placement associated with Impression Level Revenue Data.
    /// - parameter jsonData: The Impression Level Revenue Data JSON.
    init(placement: String, jsonData: [String: Any]) {
        self.placement = placement
        // Process the ILRD payload, stripping out any JSON null instances
        let processedILRD = jsonData.filter { _, value in
            !(value is NSNull)
        }
        self.jsonData = processedILRD
    }

    @available(*, unavailable)
    override init() {
        fatalError("init() has not been implemented")
    }
}
