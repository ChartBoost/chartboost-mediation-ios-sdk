// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Publishes IRLD (Impression-level revenue data) events for the publisher to receive.
protocol ILRDEventPublisher {
    /// Posts an ILRD event.
    func postILRDEvent(forPlacement placement: String, ilrdJSON: [String: Any])
}

/// ILRDEventPublisher implementation that publishes ILRD events as Notification Center notifications.
final class NotificationCenterILRDEventPublisher: ILRDEventPublisher {
    @Injected(\.taskDispatcher) private var taskDispatcher

    /// Fires the `chartboostMediationDidReceiveILRD` notification on the main thread.
    /// - parameter placement: Placement that the ILRD is associated with.
    /// - parameter ilrdJSON: ILRD JSON to send.
    func postILRDEvent(forPlacement placement: String, ilrdJSON: [String: Any]) {
        // Create the ILRD object.
        let irld = ImpressionData(placement: placement, jsonData: ilrdJSON)
        // Post the notification synchronously on the main thread so that the current
        // execution won't be tied up, and is a failsafe in case the publisher notification
        // handler performs UI manipulation.
        taskDispatcher.async(on: .main) {
            NotificationCenter.default.post(name: .chartboostMediationDidReceiveILRD, object: irld)
        }
    }
}
