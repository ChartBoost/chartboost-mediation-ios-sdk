// Copyright 2025-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

/// ServerEventTracker represents a tracking event that is sent to a server.
/// Each event is associated with a specific URL where the event data is posted.
/// This struct conforms to `Codable` to support encoding and decoding.
///
/// - Properties:
///   - url: The destination URL where the event is sent.
struct ServerEventTracker: Codable, Equatable {
    let url: URL
}

extension ServerEventTracker {
    static var defaultInitialization: ServerEventTracker {
         guard let url = URL(string: "https://initialization.mediation-sdk.chartboost.com/v1/event/initialization") else {
             fatalError("Default initialization URL is invalid")
         }
         return ServerEventTracker(url: url)
     }

    var isValid: Bool {
        URL(unsafeString: url.absoluteString) != nil
    }
}
