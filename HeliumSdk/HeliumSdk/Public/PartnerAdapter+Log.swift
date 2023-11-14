// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides logging capabilities to partner adapters.
/// All functionality is provided by default implementations.
public extension PartnerAdapter {
    
    /// Logs a predefined message from a list of standard events.
    /// You may pass a `String` literal which will be understood as a ``PartnerLogEvent/custom(_:)`` event.
    /// - note: A default implementation is provided, so you don't need to implement this method in your adapter.
    func log(_ event: PartnerLogEvent, functionName: StaticString = #function) {
        PartnerLogger().log(event, from: self, functionName: functionName)
    }
}

/// List of predefined events for ``PartnerAdapter`` types to log.
public enum PartnerLogEvent: ExpressibleByStringInterpolation {
    /// To log when setUp() is called.
    case setUpStarted
    /// To log when the partner finishes setting up successfully.
    case setUpSucceded
    /// To log when the partner finishes setting up with a failure.
    case setUpFailed(Error)
    
    /// To log when fetchBidderInformation() is called.
    case fetchBidderInfoStarted(PreBidRequest)
    /// To log when the partner finishes fetching bidder info successfully.
    case fetchBidderInfoSucceeded(PreBidRequest)
    /// To log when the partner finishes fetching bidder info with a failure.
    case fetchBidderInfoFailed(PreBidRequest, error: Error)
    
    /// To log when an update to any privacy setting is sent to a partner SDK.
    /// Pass the name that the partner SDK uses for this privacy setting, and the new value it is being set to.
    case privacyUpdated(setting: String, value: Any?)
    
    /// A custom log message for events that do not correspond to any of the predefined event `cases`.
    /// - note: You may just pass a `String` in ``PartnerAdapter/log(_:functionName:)`` to log a custom event instead of using this case directly.
    case custom(String)
    
    // This init allows us to create custom events from string literals.
    public init(stringLiteral value: String) {
        self = .custom(value)
    }
    
    // This init allows us to create custom events from string interpolations.
    public init(stringInterpolation: DefaultStringInterpolation) {
        // The documentation states to not use String(stringInterpolation:) directly. Instead,
        // we can use String(describing:) or String interpolation, both seem to work the same.
        self = .custom(String(describing: stringInterpolation))
    }
}
