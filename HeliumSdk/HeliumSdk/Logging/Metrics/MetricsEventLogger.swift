// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

typealias AuctionID = String
typealias LoadID = String

/// A raw dictionary representation of a metrics request body sent to our backend.
typealias RawMetrics = [String: Any]

protocol MetricsEventLogging {
    
    /// Logs a initialization event.
    func logInitialization(_ events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?)
    
    /// Logs a prebid event.
    func logPrebid(loadID: LoadID, events: [MetricsEvent])
    
    /// Logs a load event.
    /// - returns: Raw metrics dictionary sent to our backend.
    func logLoad(auctionID: AuctionID, loadID: LoadID, events: [MetricsEvent], error: ChartboostMediationError?, adFormat: AdFormat, size: CGSize?) -> RawMetrics?
    
    /// Logs a show event.
    func logShow(auctionID: AuctionID, loadID: LoadID, event: MetricsEvent) -> RawMetrics?
    
    /// Logs a click event.
    func logClick(auctionID: AuctionID, loadID: LoadID)
    
    /// Logs an expiration event.
    func logExpiration(auctionID: AuctionID, loadID: LoadID)
    
    /// Logs a Helium ad impression.
    /// This is when we consider that the ad is visible, which may not be the same as when the partner that shows the ad considers the ad is visible.
    /// - parameter ad: The partner ad affected.
    func logHeliumImpression(for ad: PartnerAd)
    
    /// Logs a partner ad impression.
    /// This is when the partner that shows the ad considers that the ad is visible, which may not be the same as when we consider the ad is visible.
    /// - parameter ad: The partner ad affected.
    func logPartnerImpression(for ad: PartnerAd)
    
    /// Logs a reward event.
    /// - parameter ad: The partner ad affected.
    func logReward(for ad: PartnerAd)
    
    /// Logs that the ad auction is finished.
    /// - parameter bids: The participating bids in the auction.
    func logAuctionCompleted(
        with bids: [Bid],
        winner: Bid,
        loadID: LoadID,
        adFormat: AdFormat,
        size: CGSize?
    )
    
    /// Asynchronously notifies the endpoint specified at the rewarded callback URL that the user has earned a reward.
    /// This method will retry the callback attempt the number of times as specified in `RewardedCallback.maxRetries` property before giving up.
    /// - parameter rewardedCallback: The rewarded callback model containing all the info needed to make the HTTP request.
    /// - parameter customData: Extra info passed programmatically by the publisher to be sent in the rewarded callback request.
    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?)
}

protocol MetricsEventLoggerConfiguration {
    /// The list of enabled event types.
    var filter: [MetricsEvent.EventType] { get }
    /// The country associated with the load, specified by the backend.
    var country: String? { get }
    /// An internal test identifier obtained and passed back to the backend for tracking purposes.
    var testIdentifier: String? { get }
 }

/// A `MetricsEventLogging` implementation for logging to the backend to the appropriate endpoint as dicated by the
/// event type.
final class MetricsEventLogger: MetricsEventLogging {

    @Injected(\.metricsConfiguration) private var configuration
    /// Indicates Helium SDK initialization status.
    @Injected(\.initializationStatusProvider) private var initializationStatusProvider
    @Injected(\.networkManager) private var networkManager
    
    func logInitialization(_ events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) {
        guard configuration.filter.contains(.initialization) else { return }

        send(MetricsHTTPRequest.initialization(events: events, result: result, error: error))
        logToConsole(.initialization, events: events, error: error)
    }

    func logPrebid(loadID: LoadID, events: [MetricsEvent]) {
        guard !events.isEmpty else { return }
        guard configuration.filter.contains(.prebid) else { return }
        
        send(MetricsHTTPRequest.prebid(loadID: loadID, events: events))
        logToConsole(.prebid, events: events)
    }
    
    func logLoad(
        auctionID: AuctionID,
        loadID: LoadID,
        events: [MetricsEvent],
        error: ChartboostMediationError?,
        adFormat: AdFormat,
        size: CGSize?
    ) -> RawMetrics? {
        guard configuration.filter.contains(.load) else { return nil }

        let request = MetricsHTTPRequest.load(
            auctionID: auctionID,
            loadID: loadID,
            events: events,
            error: error,
            adFormat: adFormat,
            size: size
        )
        var metrics = send(request)
        logToConsole(.load, auctionID: auctionID, loadID: loadID, events: events)
        // Since the `loadID` is sent in the header, it's not part of the dict that's provided
        // to the pub. Add it after logging to the console, since the `loadID` is logged as part
        // of that.
        metrics?["load_id"] = loadID
        return metrics
    }

    func logShow(auctionID: AuctionID, loadID: LoadID, event: MetricsEvent) -> RawMetrics? {
        guard configuration.filter.contains(.show) else { return nil }
        
        let metrics = send(MetricsHTTPRequest.show(auctionID: auctionID, loadID: loadID, event: event))
        logToConsole(.show, auctionID: auctionID, loadID: loadID, events: [event])
        return metrics
    }

    func logClick(auctionID: AuctionID, loadID: LoadID) {
        guard configuration.filter.contains(.click) else { return }
        
        send(MetricsHTTPRequest.click(auctionID: auctionID, loadID: loadID))
        logToConsole(.click, auctionID: auctionID, loadID: loadID)
    }

    func logExpiration(auctionID: AuctionID, loadID: LoadID) {
        guard configuration.filter.contains(.expiration) else { return }
        
        send(MetricsHTTPRequest.expiration(auctionID: auctionID, loadID: loadID))
        logToConsole(.expiration, auctionID: auctionID, loadID: loadID)
    }
    
    func logHeliumImpression(for ad: PartnerAd) {
        send(MetricsHTTPRequest.heliumImpression(
            auctionID: ad.request.auctionIdentifier,
            loadID: ad.request.loadID
        ))
        logToConsole(.heliumImpression, auctionID: ad.request.auctionIdentifier, loadID: ad.request.loadID)
    }
    
    func logPartnerImpression(for ad: PartnerAd) {
        send(MetricsHTTPRequest.partnerImpression(
            auctionID: ad.request.auctionIdentifier,
            loadID: ad.request.loadID
        ))
        logToConsole(.partnerImpression, auctionID: ad.request.auctionIdentifier, loadID: ad.request.loadID)
    }
    
    func logReward(for ad: PartnerAd) {
        send(MetricsHTTPRequest.reward(
            auctionID: ad.request.auctionIdentifier,
            loadID: ad.request.loadID
        ))
        logToConsole(.reward, auctionID: ad.request.auctionIdentifier, loadID: ad.request.loadID)
    }
    
    func logAuctionCompleted(
        with bids: [Bid],
        winner: Bid,
        loadID: LoadID,
        adFormat: AdFormat,
        size: CGSize?
    ) {
        let request = WinnerEventHTTPRequest(
            winner: winner,
            of: bids,
            loadID: loadID,
            adFormat: adFormat,
            size: size
        )
        networkManager.send(request) { _ in }
    }
    
    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?) {
        guard let request = RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: customData) else {
            return
        }
        networkManager.send(request) { _ in }
    }
    
    private func logToConsole(
        _ eventType: MetricsEvent.EventType,
        auctionID: AuctionID? = nil,
        loadID: LoadID? = nil,
        events: [MetricsEvent]? = nil,
        error: ChartboostMediationError? = nil
    ) {
        let auctionIDInfo = auctionID.map { "auction_id = \($0)" } ?? ""
        let loadIDInfo = loadID.map { "load ID = \($0)" } ?? ""
        let errorInfo = error.map { "error = \($0)" } ?? ""
        if let events = events {
            events.forEach {
                logger.trace("Metrics data for \(eventType): [\(auctionIDInfo)][\(loadIDInfo)] \($0.logString), \(errorInfo)")
            }
        } else {
            logger.trace("Metrics data for \(eventType): [\(auctionIDInfo)][\(loadIDInfo)] \(errorInfo)")
        }
    }
}

// MARK: - Helpers

private extension MetricsEvent {
    
    var logString: String {
        var parts = [String]()
        parts.append("partner = \(partnerIdentifier)")
        if let lineItemIdentifier = lineItemIdentifier {
            parts.append("lineItemId = \(lineItemIdentifier)")
        }
        if let partnerSDKVersion = partnerSDKVersion {
            parts.append("partnerSDKVersion = \(partnerSDKVersion)")
        }
        if let partnerAdapterVersion = partnerAdapterVersion {
            parts.append("partnerAdapterVersion = \(partnerAdapterVersion)")
        }
        if let networkType = networkType {
            parts.append("networkType = \(networkType.rawValue)")
        }
        if let partnerPlacement = partnerPlacement {
            parts.append("partnerPlacement = \(partnerPlacement)")
        }
        parts.append("start = \(start.unixTimestamp)")
        parts.append("end = \(end.unixTimestamp)")
        parts.append("duration = \(Int64(duration * 1000))")
        if let error = error {
            parts.append("chartboostMediationError = \(error.chartboostMediationCode.name)")
            parts.append("chartboostMediationErrorCode = \(error.chartboostMediationCode.string)")
            parts.append("errorMessage = \(error.chartboostMediationCode.message)")
        }
        parts.append("isSuccess = \(error == nil)")
        return parts.joined(separator: ", ")
    }
}

extension MetricsEventLogging {
    /// A convenience alternative of the formal `logShow()`.
    func logShow(ad: HeliumAd, start: Date, error: ChartboostMediationError?) -> RawMetrics? {
        logShow(
            auctionID: ad.partnerAd.request.auctionIdentifier,
            loadID: ad.request.loadID,
            event: MetricsEvent(
                start: start,
                error: error,
                partnerIdentifier: ad.partnerAd.request.partnerIdentifier
            )
        )
    }
}

private extension MetricsEventLogger {

    @discardableResult
    func send(_ request: MetricsHTTPRequest) -> RawMetrics? {
        networkManager.send(request) { _ in }

        switch request.eventType {
        case .load, .show:
            return request.bodyJSON
        default:
            return nil
        }
    }
}
