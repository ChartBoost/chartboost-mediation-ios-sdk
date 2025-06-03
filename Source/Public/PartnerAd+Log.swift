// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Provides logging capabilities to partner ads.
/// All functionality is provided by default implementations.
extension PartnerAd {
    /// Logs a predefined message from a list of standard events.
    /// You may pass a `String` literal which will be understood as a ``PartnerLogEvent/custom(_:)`` event.
    /// - note: A default implementation is provided, so you don't need to implement this method in your adapter.
    public func log(_ event: PartnerAdLogEvent, functionName: StaticString = #function) {
        PartnerLogger().log(event, from: self, functionName: functionName)
    }
}

/// List of predefined events for ``PartnerAd`` types to log.
public enum PartnerAdLogEvent: ExpressibleByStringInterpolation {
    /// To log when load() is called.
    case loadStarted
    /// To log when the partner finishes a load successfully.
    case loadSucceeded
    /// To log when the partner finishes a load with a failure.
    case loadFailed(Error)
    /// To log when the partner load result is ignored because it was unexpected or because the ``PartnerAd`` load completion is
    /// otherwise unavailable.
    case loadResultIgnored

    /// To log when invalidate() is called.
    case invalidateStarted
    /// To log when the partner finishes invalidating an ad successfully.
    case invalidateSucceeded
    /// To log when the partner finishes invalidating an ad with a failure.
    case invalidateFailed(Error)

    /// To log when show() is called.
    case showStarted
    /// To log when the partner finishes a show successfully.
    case showSucceeded
    /// To log when the partner finishes a show with a failure.
    case showFailed(Error)
    /// To log when the partner show result is ignored because it was unexpected or because the ``PartnerAd`` show completion is otherwise
    /// unavailable.
    case showResultIgnored

    /// To log when the partner tracks an impression.
    case didTrackImpression
    /// To log when the partner tracks a click.
    case didClick(error: Error?)
    /// To log when the partner gives a reward.
    case didReward
    /// To log when the partner dismissed the ad.
    case didDismiss(error: Error?)
    /// To log when the partner marked an ad as expired.
    case didExpire
    /// To log when an ad life-cycle event cannot be reported to the ``PartnerAdDelegate`` because it is unavailable.
    case delegateUnavailable
    /// To log when a partner delegate method call is ignored by the adapter because it has no corresponding ``PartnerAdDelegate`` method.
    case delegateCallIgnored

    /// A custom log message for events that do not correspond to any of the predefined event `cases`.
    /// - note: You may just pass a `String` in ``PartnerAd/log(_:functionName:)`` to log a custom event instead of using this
    /// case directly.
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
