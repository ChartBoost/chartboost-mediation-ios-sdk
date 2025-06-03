// Copyright 2018-2025 Chartboost, Inc.
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
    func logPrebid(for request: PartnerAdPreBidRequest, events: [MetricsEvent])

    /// Logs a load event.
    /// - returns: Raw metrics dictionary sent to our backend.
    func logLoad(
        auctionID: AuctionID,
        loadID: LoadID,
        events: [MetricsEvent],
        error: ChartboostMediationError?,
        adFormat: AdFormat,
        size: CGSize?,
        start: Date,
        end: Date,
        backgroundDuration: TimeInterval,
        queueID: String?,
        partnerAd: PartnerAd?
    ) -> RawMetrics?

    /// Logs a show event.
    func logShow(for ad: LoadedAd, start: Date, error: ChartboostMediationError?) -> RawMetrics?

    /// Logs a click event.
    func logClick(for ad: PartnerAd)

    /// Logs an expiration event.
    func logExpiration(for ad: PartnerAd)

    /// Logs a Chartboost Mediation ad impression.
    /// This is when we consider that the ad is visible, which may not be the same as when the partner that shows the ad considers the
    /// ad is visible.
    /// - parameter ad: The loaded ad affected.
    func logMediationImpression(for ad: LoadedAd)

    /// Logs a partner ad impression.
    /// This is when the partner that shows the ad considers that the ad is visible, which may not be the same as when we consider the
    /// ad is visible.
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
    /// This method will retry the callback attempt the number of times as specified in `RewardedCallback.maxRetries` property before
    /// giving up.
    /// - parameter rewardedCallback: The rewarded callback model containing all the info needed to make the HTTP request.
    /// - parameter customData: Extra info passed programmatically by the publisher to be sent in the rewarded callback request.
    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?)

    /// Logs that a queue has been given a new unique ID and will run until .stop() is called on the queue.
    func logStartQueue(_ queue: FullscreenAdQueue)

    /// Logs that .stop() has been called on a running queue. The queue will discard the current queueID and will not request any
    /// more ads unless restarted.
    func logEndQueue(_ queue: FullscreenAdQueue)

    /// Logs an informative warning message to alert against potential issues related to its dimensions.
    func logContainerTooSmallWarning(adFormat: AdFormat, data: AdaptiveBannerSizeData, loadID: String)
}

extension MetricsEventLogging {
    /// Logs a load event. The `end` date is set to now.
    /// - returns: Raw metrics dictionary sent to our backend.
    func logLoad(
        auctionID: AuctionID,
        loadID: LoadID,
        events: [MetricsEvent],
        error: ChartboostMediationError?,
        adFormat: AdFormat,
        size: CGSize?,
        start: Date,
        backgroundDuration: TimeInterval,
        queueID: String? = nil,
        partnerAd: PartnerAd? = nil
    ) -> RawMetrics? {
        self.logLoad(
            auctionID: auctionID,
            loadID: loadID,
            events: events,
            error: error,
            adFormat: adFormat,
            size: size,
            start: start,
            end: Date(),
            backgroundDuration: backgroundDuration,
            queueID: queueID,
            partnerAd: partnerAd
        )
    }
}

protocol MetricsEventLoggerConfiguration {
    var eventTrackers: [MetricsEvent.EventType: [ServerEventTracker]] { get }
    /// The country associated with the load, specified by the backend.
    var country: String? { get }
    /// An internal test identifier obtained and passed back to the backend for tracking purposes.
    var testIdentifier: String? { get }
 }

/// A `MetricsEventLogging` implementation for logging to the backend to the appropriate endpoint as dicated by the
/// event type.
final class MetricsEventLogger: MetricsEventLogging {
    @Injected(\.environment) private var environment
    @Injected(\.metricsConfiguration) private var configuration
    /// Indicates Mediation SDK initialization status.
    @Injected(\.initializationStatusProvider) private var initializationStatusProvider
    @Injected(\.networkManager) private var networkManager

    func logInitialization(_ metricsEvent: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) {
        guard shouldLogEvent(.initialization) else { return }
        for tracker in eventTrackers(for: .initialization) {
            let request = MetricsHTTPRequest.initialization(eventTracker: tracker, metricsEvent: metricsEvent, result: result, error: error)
            send(request)
        }
        logToConsole(.initialization, events: metricsEvent, error: error)
    }

    func logPrebid(for request: PartnerAdPreBidRequest, events: [MetricsEvent]) {
        guard !events.isEmpty else { return }
        guard shouldLogEvent(.prebid) else { return }
        for trackerEvents in eventTrackers(for: .prebid) {
            let request = MetricsHTTPRequest.prebid(
                eventTracker: trackerEvents,
                adFormat: request.internalAdFormat,
                loadID: request.loadID,
                metricsEvents: events
            )
            send(request)
        }
        logToConsole(.prebid, events: events)
    }

    func logLoad(
        auctionID: AuctionID,
        loadID: LoadID,
        events: [MetricsEvent],
        error: ChartboostMediationError?,
        adFormat: AdFormat,
        size: CGSize?,
        start: Date,
        end: Date,
        backgroundDuration: TimeInterval,
        queueID: String? = nil,
        partnerAd: PartnerAd? = nil
    ) -> RawMetrics? {
        guard shouldLogEvent(.load) else { return nil }
        let trackers = eventTrackers(for: .load, partnerAd: partnerAd)
        var metrics: RawMetrics?
        for tracker in trackers {
            let request = MetricsHTTPRequest.load(
                eventTracker: tracker,
                auctionID: auctionID,
                loadID: loadID,
                metricsEvent: events,
                error: error,
                adFormat: adFormat,
                size: size,
                start: start,
                end: end,
                backgroundDuration: backgroundDuration,
                queueID: queueID
            )
            send(request)

            // Set metrics to return (value is overwritten for each tracker but it's fine since they all should have
            // the same body).
            metrics = request.bodyJSON

            // Since the `loadID` is sent in the header, it's not part of the dict that's provided
            // to the pub. Add it after logging to the console, since the `loadID` is logged as part
            // of that.
            metrics?["load_id"] = loadID
        }
        logToConsole(.load, auctionID: auctionID, loadID: loadID, events: events)
        return metrics
    }

    func logShow(for ad: LoadedAd, start: Date, error: ChartboostMediationError?) -> RawMetrics? {
        guard shouldLogEvent(.show) else { return nil }
        let trackers = eventTrackers(for: .show, ad: ad)
        guard !trackers.isEmpty else { return nil }
        let event = MetricsEvent(
            start: start,
            error: error,
            partnerID: ad.partnerAd.request.partnerID
        )

        var metrics: RawMetrics?

        // Send to all trackers
        for tracker in trackers {
            let request = MetricsHTTPRequest.show(
                eventTracker: tracker,
                adFormat: ad.request.adFormat,
                auctionID: ad.partnerAd.request.auctionID,
                loadID: ad.request.loadID,
                metricsEvent: event
            )
            send(request)
            metrics = request.bodyJSON  // Last request's bodyJSON is returned
        }

        logToConsole(.show, auctionID: ad.partnerAd.request.auctionID, loadID: ad.request.loadID, events: [event])
        return metrics
    }

    func logClick(for ad: PartnerAd) {
        guard shouldLogEvent(.click) else { return }
        let request = ad.request
        for tracker in eventTrackers(for: .click, partnerAd: ad) {
            send(
                MetricsHTTPRequest.click(
                    eventTracker: tracker,
                    adFormat: request.internalAdFormat,
                    auctionID: request.auctionID,
                    loadID: request.loadID
                )
            )
        }
        logToConsole(.click, auctionID: ad.request.auctionID, loadID: ad.request.loadID)
    }

    func logExpiration(for ad: PartnerAd) {
        guard shouldLogEvent(.expiration) else { return }
        let request = ad.request
        for tracker in eventTrackers(for: .expiration, partnerAd: ad) {
            send(
                MetricsHTTPRequest.expiration(
                    eventTracker: tracker,
                    adFormat: request.internalAdFormat,
                    auctionID: request.auctionID,
                    loadID: request.loadID
                )
            )
        }
        logToConsole(.expiration, auctionID: ad.request.auctionID, loadID: ad.request.loadID)
    }

    func logMediationImpression(for ad: LoadedAd) {
        for tracker in eventTrackers(for: .mediationImpression, ad: ad) {
            send(MetricsHTTPRequest.mediationImpression(
                eventTracker: tracker,
                adFormat: ad.request.adFormat,
                size: ad.bannerSize?.size,
                auctionID: ad.auctionID,
                loadID: ad.request.loadID,
                bidders: ad.bidders,
                winner: ad.winner.partnerID,
                type: ad.type,
                price: ad.price,
                lineItemID: ad.winner.lineItemIdentifier,
                partnerPlacement: ad.winner.isProgrammatic ? nil : ad.winner.partnerPlacement
            ))
        }
        logToConsole(.mediationImpression, auctionID: ad.auctionID, loadID: ad.request.loadID)
    }

    func logPartnerImpression(for ad: PartnerAd) {
        let request = ad.request
        for tracker in eventTrackers(for: .partnerImpression, partnerAd: ad) {
            send(MetricsHTTPRequest.partnerImpression(
                eventTracker: tracker,
                adFormat: request.internalAdFormat,
                auctionID: request.auctionID,
                loadID: request.loadID
            ))
        }
        logToConsole(.partnerImpression, auctionID: request.auctionID, loadID: request.loadID)
    }

    func logReward(for ad: PartnerAd) {
        let request = ad.request
        for tracker in eventTrackers(for: .reward, partnerAd: ad) {
            send(MetricsHTTPRequest.reward(
                eventTracker: tracker,
                adFormat: request.internalAdFormat,
                auctionID: request.auctionID,
                loadID: request.loadID
            ))
        }
        logToConsole(.reward, auctionID: request.auctionID, loadID: request.loadID)
    }

    func logAuctionCompleted(
        with bids: [Bid],
        winner: Bid,
        loadID: LoadID,
        adFormat: AdFormat,
        size: CGSize?
    ) {
        for tracker in eventTrackers(for: .winner) {
            let request = WinnerEventHTTPRequest(
                eventTracker: tracker,
                winner: winner,
                of: bids,
                loadID: loadID,
                adFormat: adFormat,
                size: size
            )
            networkManager.send(request) { _ in }
        }
    }

    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?) {
        guard let request = RewardedCallbackHTTPRequest(rewardedCallback: rewardedCallback, customData: customData) else {
            return
        }
        networkManager.send(request) { _ in }
    }

    func logStartQueue(_ queue: FullscreenAdQueue) {
        for tracker in eventTrackers(for: .startQueue) {
            let event = StartQueueEventHTTPRequest(
                eventTracker: tracker,
                actualMaxQueueSize: queue.maxQueueSize,
                appID: environment.app.chartboostAppID ?? "",
                currentQueueDepth: queue.numberOfAdsReady,
                placementName: queue.placement,
                queueCapacity: queue.queueCapacity,
                queueID: queue.queueID
            )
            networkManager.send(event) { _ in }
            logger.log("Starting queue for placement \(queue.placement)", level: .info)
        }
    }

    func logEndQueue(_ queue: FullscreenAdQueue) {
        for tracker in eventTrackers(for: .endQueue) {
            let event = EndQueueEventHTTPRequest(
                eventTracker: tracker,
                appID: environment.app.chartboostAppID ?? "",
                currentQueueDepth: queue.numberOfAdsReady,
                placementName: queue.placement,
                queueCapacity: queue.queueCapacity,
                queueID: queue.queueID
            )
            networkManager.send(event) { _ in }
            logger.log("Stopping queue for placement \(queue.placement)", level: .info)
        }
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
        if let events {
            events.forEach {
                logger.verbose("Metrics data for \(eventType): [\(auctionIDInfo)][\(loadIDInfo)] \($0.logString), \(errorInfo)")
            }
        } else {
            logger.verbose("Metrics data for \(eventType): [\(auctionIDInfo)][\(loadIDInfo)] \(errorInfo)")
        }
    }

    func logContainerTooSmallWarning(adFormat: AdFormat, data: AdaptiveBannerSizeData, loadID: String) {
        for tracker in eventTrackers(for: .bannerSize) {
            let request = AdaptiveBannerSizeHTTPRequest(eventTracker: tracker, adFormat: adFormat, data: data, loadID: loadID)
            networkManager.send(request) { _ in }
        }
    }

    private func eventTrackers(
        for eventType: MetricsEvent.EventType,
        ad: LoadedAd? = nil,
        partnerAd: PartnerAd? = nil
    ) -> [ServerEventTracker] {
        let sdkTrackers = configuration.eventTrackers[eventType] ?? []
        let bidTrackers = ad?.winner.eventTrackers[eventType] ?? []
        let partnerTrackers = partnerAd?.request.eventTrackers[eventType] ?? []

        return sdkTrackers + bidTrackers + partnerTrackers
    }
}

// MARK: - Helpers

extension MetricsEvent {
    fileprivate var logString: String {
        var parts = [String]()
        parts.append("partner = \(partnerID)")
        if let lineItemIdentifier {
            parts.append("lineItemId = \(lineItemIdentifier)")
        }
        if let partnerSDKVersion {
            parts.append("partnerSDKVersion = \(partnerSDKVersion)")
        }
        if let partnerAdapterVersion {
            parts.append("partnerAdapterVersion = \(partnerAdapterVersion)")
        }
        if let networkType {
            parts.append("networkType = \(networkType.rawValue)")
        }
        if let partnerPlacement {
            parts.append("partnerPlacement = \(partnerPlacement)")
        }
        parts.append("start = \(start.unixTimestamp)")
        parts.append("end = \(end.unixTimestamp)")
        parts.append("duration = \(Int64(duration * 1000))")
        if let error {
            parts.append("chartboostMediationError = \(error.chartboostMediationCode.name)")
            parts.append("chartboostMediationErrorCode = \(error.chartboostMediationCode.string)")
            parts.append("errorMessage = \(error.chartboostMediationCode.message)")
        }
        parts.append("isSuccess = \(error == nil)")
        return parts.joined(separator: ", ")
    }
}

extension MetricsEventLogger {
    private func send(_ request: MetricsHTTPRequest) {
        networkManager.send(request) { _ in }
    }

    // TODO: temperary solution, need to remove (HB-9161).
    private func shouldLogEvent(_ eventType: MetricsEvent.EventType) -> Bool {
        return configuration.eventTrackers[eventType] != nil
    }
}
