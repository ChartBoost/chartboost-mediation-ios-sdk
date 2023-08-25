// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol InitResultsEventPublisher {
    /// Posts an initialization event.
    func postInitResultsEvent(_ event: InitResultsEvent)
}

/// An event with information about the initialization status of all partner adapters.
struct InitResultsEvent: Encodable {
    
    struct InProgress: Encodable {
        let partner: String
        let start: Date
    }
    
    let sessionId: String
    let skipped: [String]
    let success: [MetricsEvent]
    let failure: [MetricsEvent]
    let inProgress: [InProgress]
}

/// InitEventPublisher implementation that publishes initialization events as Notification Center notifications.
final class NotificationCenterInitResultsEventPublisher: InitResultsEventPublisher {
    
    @Injected(\.taskDispatcher) private var taskDispatcher
    @Injected(\.jsonSerializer) private var jsonSerializer
    
    /// Fires the `heliumDidReceiveInit` notification on the main thread.
    func postInitResultsEvent(_ event: InitResultsEvent) {
        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(event)
            let json = try jsonSerializer.deserialize(data) as [String: Any]
            // Post the notification synchronously on the main thread so that the current
            // execution won't be tied up, and is a failsafe in case the publisher notification
            // handler performs UI manipulation.
            taskDispatcher.async(on: .main) {
                NotificationCenter.default.post(name: .heliumDidReceiveInitResults, object: json)
            }
        }
        catch {
            logger.error("Failed to post init results with error: \(error)")
        }
    }
}
