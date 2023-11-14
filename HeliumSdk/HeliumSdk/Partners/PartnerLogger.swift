// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Logs partner events in the console.
struct PartnerLogger {
    
    /// Logs a console message for a partner adapter event.
    func log(_ event: PartnerLogEvent, from adapter: PartnerAdapter, functionName: StaticString) {
        logger(for: adapter).log(message(for: event), level: event.logLevel)
    }
    
    /// Logs a console message for a partner ad event.
    func log(_ event: PartnerAdLogEvent, from ad: PartnerAd, functionName: StaticString) {
        logger(for: ad.adapter).log(message(for: event, from: ad, functionName: functionName), level: event.logLevel)
    }
}

private extension PartnerLogger {
    
    func logger(for adapter: PartnerAdapter) -> Logger {
        Logger(subsystem: "com.chartboost.mediation.adapter", category: "\(adapter.partnerDisplayName) Adapter")
    }
    
    func message(for event: PartnerLogEvent) -> String {
        switch event {
        case .setUpStarted:
            return "Setup started"
        case .setUpSucceded:
            return "Setup succeeded"
        case .setUpFailed(let error):
            return "Setup failed with error: \(message(for: error))"
        case .fetchBidderInfoStarted(let request):
            return "Fetch bidder info started for \(request.format) ad with placement \(request.chartboostPlacement)"
        case .fetchBidderInfoSucceeded(let request):
            return "Fetch bidder info succeeded for \(request.format) ad with placement \(request.chartboostPlacement)"
        case .fetchBidderInfoFailed(let request, let error):
            return "Fetch bidder info failed for \(request.format) ad with placement \(request.chartboostPlacement) and error: \(message(for: error))"
        case .privacyUpdated(let setting, let value):
            return "Set \(setting) to \(value ?? "nil")"
        case .custom(let string):
            return string
        }
    }
    
    func message(for event: PartnerAdLogEvent, from ad: PartnerAd, functionName: StaticString) -> String {
        switch event {
        case .loadStarted:
            return "Load started for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .loadSucceeded:
            return "Load succeeded for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .loadFailed(let error):
            return "Load failed for \(ad.request.format) ad with placement \(ad.request.partnerPlacement) and error: \(message(for: error))"
        case .loadResultIgnored:
            return "Load result ignored"
        case .invalidateStarted:
            return "Invalidate started for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .invalidateSucceeded:
            return "Invalidate succeeded for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .invalidateFailed(let error):
            return "Invalidate failed for \(ad.request.format) ad with placement \(ad.request.partnerPlacement) and error: \(message(for: error))"
        case .showStarted:
            return "Show started for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .showSucceeded:
            return "Show succeeded for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .showFailed(let error):
            return "Show failed for \(ad.request.format) ad with placement \(ad.request.partnerPlacement) and error: \(message(for: error))"
        case .showResultIgnored:
            return "Show result ignored"
        case .didTrackImpression:
            return "Tracked impression for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .didClick(let error):
            return "Clicked \(ad.request.format) ad with placement \(ad.request.partnerPlacement)" + (error.map { "and error: \(message(for: $0))" } ?? "")
        case .didReward:
            return "Rewarded \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .didDismiss(let error):
            return "Dismissed \(ad.request.format) ad with placement \(ad.request.partnerPlacement)" + (error.map { "and error: \(message(for: $0))" } ?? "")
        case .didExpire:
            return "Expired \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .delegateUnavailable:
            return "Delegate unavailable"
        case .delegateCallIgnored:
            return "Got \(functionName) call for \(ad.request.format) ad with placement \(ad.request.partnerPlacement)"
        case .custom(let string):
            return string
        }
    }
    
    /// Returns a proper message for Helium errors created by the `PartnerAdapter.error()` method, or a default error description.
    func message(for error: Error) -> String {
        guard let error = error as? ChartboostMediationError else {
            return "'\((error as NSError).description)'"
        }
        var message = error.chartboostMediationCode.name
        if let description = error.userInfo[NSLocalizedFailureErrorKey] as? String {
            message += ", description: '\(description)'"
        }
        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            message += ", partner error: '\(underlyingError.description)'"
        }
        return message
    }
}

extension PartnerLogEvent {
    var logLevel: LogLevel {
        switch self {
        case .setUpStarted:
            return .debug
        case .setUpSucceded:
            return .info
        case .setUpFailed:
            return .error

        case .fetchBidderInfoStarted:
            return .debug
        case .fetchBidderInfoSucceeded:
            return .info
        case .fetchBidderInfoFailed:
            return .error
        case .privacyUpdated:
            return .debug
        case .custom:
            return .info
        }
    }
}

extension PartnerAdLogEvent {
    var logLevel: LogLevel {
        switch self {
        case .loadStarted:
            return .debug
        case .loadSucceeded:
            return .info
        case .loadFailed:
            return .error
        case .loadResultIgnored:
            return .info
        case .invalidateStarted:
            return .debug
        case .invalidateSucceeded:
            return .info
        case .invalidateFailed:
            return .error
        case .showStarted:
            return .debug
        case .showSucceeded:
            return .info
        case .showFailed:
            return .error
        case .showResultIgnored:
            return .info
        case .didTrackImpression:
            return .info
        case .didClick(let error):
            return error != nil ? .error : .info
        case .didReward:
            return .info
        case .didDismiss(let error):
            return error != nil ? .error : .info
        case .didExpire:
            return .info
        case .delegateUnavailable:
            return .warning
        case .delegateCallIgnored:
            return .debug
        case .custom:
            return .info
        }
    }
}
