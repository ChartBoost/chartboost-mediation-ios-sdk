// Copyright 2025-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class MetricsEventLoggerTests: ChartboostMediationTestCase {

    let metricsLogger = MetricsEventLogger()

    // MARK: - Initialization

    func testLogInitialization_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string:"https://example.com/init")!)
        mocks.metricsConfiguration.eventTrackers[.initialization] = [tracker]

        let events = [MetricsEvent.test()]
        let result = SDKInitResult.successWithCachedConfig
        metricsLogger.logInitialization(events, result: result, error: nil)

        assertNetworkingCall(trackers: [tracker], events: events, result: result.rawValue, error: nil)
    }

    func testLogInitialization_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.initialization] = nil
        let events = [MetricsEvent.test()]
        let result = SDKInitResult.successWithFetchedConfig

        metricsLogger.logInitialization(events, result: result, error: nil)

        assertNoNetworkingCalls()
    }

    func testLogInitialization_WithError_IncludesErrorInRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/init")!)
        mocks.metricsConfiguration.eventTrackers[.initialization] = [tracker]
        let events = [MetricsEvent.test()]
        let result = SDKInitResult.failure
        let error = ChartboostMediationError(code: .internal)

        metricsLogger.logInitialization(events, result: result, error: error)

        assertNetworkingCall(trackers: [tracker], events: events, result: result.rawValue, error: error)
    }

    func testLogInitialization_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/init1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/init2")!)
        mocks.metricsConfiguration.eventTrackers[.initialization] = [tracker1, tracker2]
        let events = [MetricsEvent.test()]
        let result = SDKInitResult.successWithFetchedConfig

        metricsLogger.logInitialization(events, result: result, error: nil)

        assertNetworkingCall(trackers: [tracker1, tracker2], events: events, result: result.rawValue, error: nil)
    }

    // MARK: - Prebid

    func testLogPrebid_WithEvents_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/prebid")!)
        mocks.metricsConfiguration.eventTrackers[.prebid] = [tracker]
        let request = PartnerAdPreBidRequest.test()
        let events = [MetricsEvent.test()]

        metricsLogger.logPrebid(for: request, events: events)

        assertNetworkingCall(trackers: [tracker], events: events, adFormat: request.internalAdFormat, loadID: request.loadID)
    }

    func testLogPrebid_WithEmptyEvents_DoesNotSendRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/prebid")!)
        mocks.metricsConfiguration.eventTrackers[.prebid] = [tracker]
        let request = PartnerAdPreBidRequest.test()

        metricsLogger.logPrebid(for: request, events: [])

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogPrebid_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.prebid] = nil
        let request = PartnerAdPreBidRequest.test()
        let events = [MetricsEvent.test()]

        metricsLogger.logPrebid(for: request, events: events)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    // MARK: - Load

    func testLogLoad_WithTrackers_SendsRequestAndReturnsMetrics() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/load")!)
        mocks.metricsConfiguration.eventTrackers[.load] = [tracker]
        let adFormat = AdFormat.banner
        let auctionID = "auction123"
        let loadID = "load456"
        let events = [MetricsEvent.test()]
        let size = CGSize(width: 320, height: 50)
        let start = Date()
        let end = Date()

        let metrics = metricsLogger.logLoad(
            auctionID: auctionID,
            loadID: loadID,
            events: events,
            error: nil,
            adFormat: .banner,
            size: size,
            start: start,
            end: end,
            backgroundDuration: 0.5
        )

        assertNetworkingCall(trackers: [tracker], events: events, adFormat: adFormat, loadID: loadID)
        XCTAssertEqual(metrics?["load_id"] as? String, loadID)
    }

    func testLogLoad_WithoutTrackers_ReturnsNil() {
        mocks.metricsConfiguration.eventTrackers[.load] = nil
        let events = [MetricsEvent.test()]

        let metrics = metricsLogger.logLoad(
            auctionID: "auction",
            loadID: "load",
            events: events,
            error: nil,
            adFormat: .banner,
            size: nil,
            start: Date(),
            end: Date(),
            backgroundDuration: 0
        )

        XCTAssertNil(metrics)
        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogLoad_WithError_IncludesErrorInMetrics() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/load")!)
        mocks.metricsConfiguration.eventTrackers[.load] = [tracker]
        let error = ChartboostMediationError(code: .internal)
        let events = [MetricsEvent.test()]

        let metrics = metricsLogger.logLoad(
            auctionID: "auction",
            loadID: "load",
            events: events,
            error: error,
            adFormat: .interstitial,
            size: nil,
            start: Date(),
            end: Date(),
            backgroundDuration: 0
        )

        XCTAssertNotNil(metrics)
        assertNetworkingCall(trackers: [tracker], events: events, adFormat: .interstitial, loadID: "load", error: error)
    }

    func testLogLoad_WithQueueID_IncludesQueueIDInRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/load")!)
        mocks.metricsConfiguration.eventTrackers[.load] = [tracker]
        let queueID = "queue789"
        let events = [MetricsEvent.test()]

        let metrics = metricsLogger.logLoad(
            auctionID: "auction",
            loadID: "load",
            events: events,
            error: nil,
            adFormat: .rewarded,
            size: nil,
            start: Date(),
            end: Date(),
            backgroundDuration: 0,
            queueID: queueID
        )

        XCTAssertNotNil(metrics)
        assertNetworkingCall(trackers: [tracker], events: events, adFormat: .rewarded, loadID: "load", queueID: queueID)
    }

    func testLogLoad_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/load1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/load2")!)
        mocks.metricsConfiguration.eventTrackers[.load] = [tracker1, tracker2]
        let events = [MetricsEvent.test()]

        let metrics = metricsLogger.logLoad(
            auctionID: "auction",
            loadID: "load",
            events: events,
            error: nil,
            adFormat: .banner,
            size: nil,
            start: Date(),
            end: Date(),
            backgroundDuration: 0
        )

        assertNetworkingCall(trackers: [tracker1, tracker2], events: events, adFormat: .banner, loadID: "load")
        XCTAssertNotNil(metrics)
    }

    // MARK: - Show

    func testLogShow_WithTrackers_SendsRequestAndReturnsMetrics() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/show")!)
        mocks.metricsConfiguration.eventTrackers[.show] = [tracker]
        let ad = LoadedAd.test()
        let start = Date()

        let metrics = metricsLogger.logShow(for: ad, start: start, error: nil)

        XCTAssertNotNil(metrics)
        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.adFormat, loadID: ad.request.loadID, error: nil)
    }

    func testLogShow_WithoutTrackers_ReturnsNil() {
        mocks.metricsConfiguration.eventTrackers[.show] = nil
        let ad = LoadedAd.test()

        let metrics = metricsLogger.logShow(for: ad, start: Date(), error: nil)

        XCTAssertNil(metrics)
        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogShow_WithError_IncludesErrorInMetrics() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/show")!)
        mocks.metricsConfiguration.eventTrackers[.show] = [tracker]
        let ad = LoadedAd.test()
        let error = ChartboostMediationError(code: .internal)

        let metrics = metricsLogger.logShow(for: ad, start: Date(), error: error)

        XCTAssertNotNil(metrics)
        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.adFormat, loadID: ad.request.loadID, metricsError: error)
    }

    func testLogShow_WithMultipleTrackers_ReturnsLastRequestMetrics() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/show1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/show2")!)
        mocks.metricsConfiguration.eventTrackers[.show] = [tracker1, tracker2]
        let ad = LoadedAd.test()

        let metrics = metricsLogger.logShow(for: ad, start: Date(), error: nil)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.request.adFormat, loadID: ad.request.loadID, error: nil)
        XCTAssertNotNil(metrics)
    }

    func testLogShow_WithEmptyTrackers_ReturnsNil() {
        mocks.metricsConfiguration.eventTrackers[.show] = []
        let ad = LoadedAd.test()

        let metrics = metricsLogger.logShow(for: ad, start: Date(), error: nil)

        XCTAssertNil(metrics)
        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    // MARK: - Click

    func testLogClick_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/click")!)
        mocks.metricsConfiguration.eventTrackers[.click] = [tracker]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logClick(for: ad)

        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    func testLogClick_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.click] = nil
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logClick(for: ad)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogClick_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/click1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/click2")!)
        mocks.metricsConfiguration.eventTrackers[.click] = [tracker1, tracker2]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logClick(for: ad)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    // MARK: - Expiration

    func testLogExpiration_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/expiration")!)
        mocks.metricsConfiguration.eventTrackers[.expiration] = [tracker]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logExpiration(for: ad)

        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    func testLogExpiration_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.expiration] = nil
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logExpiration(for: ad)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogExpiration_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/expiration1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/expiration2")!)
        mocks.metricsConfiguration.eventTrackers[.expiration] = [tracker1, tracker2]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logExpiration(for: ad)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    // MARK: - Mediation Impression

    func testLogMediationImpression_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/mediation-impression")!)
        mocks.metricsConfiguration.eventTrackers[.mediationImpression] = [tracker]
        let ad = LoadedAd.test()

        metricsLogger.logMediationImpression(for: ad)

        assertNetworkingCall(trackers: [tracker], adFormat: ad.partnerAd.request.internalAdFormat, loadID: ad.request.loadID)
    }

    func testLogMediationImpression_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.mediationImpression] = nil
        let ad = LoadedAd.test()

        metricsLogger.logMediationImpression(for: ad)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogMediationImpression_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/impression1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/impression2")!)
        mocks.metricsConfiguration.eventTrackers[.mediationImpression] = [tracker1, tracker2]
        let ad = LoadedAd.test()

        metricsLogger.logMediationImpression(for: ad)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.partnerAd.request.internalAdFormat, loadID: ad.request.loadID)
    }

    // MARK: - Partner Impression

    func testLogPartnerImpression_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/partner-impression")!)
        mocks.metricsConfiguration.eventTrackers[.partnerImpression] = [tracker]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logPartnerImpression(for: ad)

        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    func testLogPartnerImpression_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.partnerImpression] = nil
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logPartnerImpression(for: ad)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogPartnerImpression_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/partner-impression1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/partner-impression2")!)
        mocks.metricsConfiguration.eventTrackers[.partnerImpression] = [tracker1, tracker2]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logPartnerImpression(for: ad)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    // MARK: - Reward

    func testLogReward_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/reward")!)
        mocks.metricsConfiguration.eventTrackers[.reward] = [tracker]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logReward(for: ad)

        assertNetworkingCall(trackers: [tracker], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    func testLogReward_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.reward] = nil
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logReward(for: ad)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogReward_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/reward1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/reward2")!)
        mocks.metricsConfiguration.eventTrackers[.reward] = [tracker1, tracker2]
        let ad = PartnerFullscreenAdMock()

        metricsLogger.logReward(for: ad)

        assertNetworkingCall(trackers: [tracker1, tracker2], adFormat: ad.request.internalAdFormat, loadID: ad.request.loadID)
    }

    // MARK: - Auction

    func testLogAuctionCompleted_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/winner")!)
        mocks.metricsConfiguration.eventTrackers[.winner] = [tracker]
        let bid1 = Bid.test()
        let bid2 = Bid.test()
        let winner = bid2

        metricsLogger.logAuctionCompleted(
            with: [bid1, bid2],
            winner: winner,
            loadID: "load123",
            adFormat: .banner,
            size: CGSize(width: 320, height: 50)
        )

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
            parameters: [
                XCTMethodSomeParameter<WinnerEventHTTPRequest> { request in
                    XCTAssertEqual(request.url, tracker.url)
                    XCTAssertEqual(request.body.auctionID, winner.auctionID)
                    XCTAssertEqual(request.body.bidders.map(\.seat), [bid1, bid2].map(\.partnerID))
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogAuctionCompleted_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/winner1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/winner2")!)
        mocks.metricsConfiguration.eventTrackers[.winner] = [tracker1, tracker2]
        let bids = [Bid.test()]
        let winner = bids[0]

        metricsLogger.logAuctionCompleted(
            with: bids,
            winner: winner,
            loadID: "load",
            adFormat: .interstitial,
            size: nil
        )

        for tracker in [tracker1, tracker2] {
            XCTAssertMethodCallPop(
                mocks.networkManagerNew,
                .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
                parameters: [
                    XCTMethodSomeParameter<WinnerEventHTTPRequest> { request in
                        XCTAssertEqual(request.url, tracker.url)
                        XCTAssertEqual(request.body.auctionID, winner.auctionID)
                        XCTAssertEqual(request.body.bidders.map(\.seat), bids.map(\.partnerID))
                    },
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter()
                ]
            )
        }
    }

    func testLogAuctionCompleted_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.winner] = nil
        let bids = [Bid.test()]
        let winner = bids[0]

        metricsLogger.logAuctionCompleted(
            with: bids,
            winner: winner,
            loadID: "load",
            adFormat: .rewarded,
            size: nil
        )

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    // MARK: - Rewarded Callback

    func testLogRewardedCallback_WithValidCallback_SendsRequest() {
        let rewardedCallback = RewardedCallback.test()
        let customData = "custom_data_123"

        metricsLogger.logRewardedCallback(rewardedCallback, customData: customData)

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
            parameters: [
                XCTMethodSomeParameter<RewardedCallbackHTTPRequest> { request in
                    XCTAssertTrue(request.url.absoluteString.contains(rewardedCallback.urlString))
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogRewardedCallback_WithoutCustomData_SendsRequest() {
        let rewardedCallback = RewardedCallback.test()

        metricsLogger.logRewardedCallback(rewardedCallback, customData: nil)

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
            parameters: [
                XCTMethodSomeParameter<RewardedCallbackHTTPRequest> { request in
                    XCTAssertEqual(request.url.absoluteString, rewardedCallback.urlString)
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogRewardedCallback_WithInvalidCallback_DoesNotSendRequest() {
        let rewardedCallback = RewardedCallback.test(urlString: "")

        metricsLogger.logRewardedCallback(rewardedCallback, customData: nil)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    // MARK: - Queue

    func testLogStartQueue_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/start-queue")!)
        mocks.metricsConfiguration.eventTrackers[.startQueue] = [tracker]
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logStartQueue(queue)

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendTHTTPRequestWithDecodableResponseHttpRequestTMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithJSONResponseTDecodableResponse,
            parameters: [
                XCTMethodSomeParameter<StartQueueEventHTTPRequest> { request in
                    XCTAssertEqual(request.url, tracker.url)
                    XCTAssertEqual(request.body.queueID, queue.queueID)
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogStartQueue_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.startQueue] = nil
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logStartQueue(queue)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogStartQueue_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/start-queue1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/start-queue2")!)
        mocks.metricsConfiguration.eventTrackers[.startQueue] = [tracker1, tracker2]
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logStartQueue(queue)

        for tracker in [tracker1, tracker2] {
            XCTAssertMethodCallPop(
                mocks.networkManagerNew,
                .sendTHTTPRequestWithDecodableResponseHttpRequestTMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithJSONResponseTDecodableResponse,
                parameters: [
                    XCTMethodSomeParameter<StartQueueEventHTTPRequest> { request in
                        XCTAssertEqual(request.url, tracker.url)
                        XCTAssertEqual(request.body.queueID, queue.queueID)
                    },
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter()
                ]
            )
        }
    }

    func testLogEndQueue_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/end-queue")!)
        mocks.metricsConfiguration.eventTrackers[.endQueue] = [tracker]
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logEndQueue(queue)

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendTHTTPRequestWithDecodableResponseHttpRequestTMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithJSONResponseTDecodableResponse,
            parameters: [
                XCTMethodSomeParameter<EndQueueEventHTTPRequest> { request in
                    XCTAssertEqual(request.url, tracker.url)
                    XCTAssertEqual(request.body.queueID, queue.queueID)
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogEndQueue_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.endQueue] = nil
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logEndQueue(queue)

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogEndQueue_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/end-queue1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/end-queue2")!)
        mocks.metricsConfiguration.eventTrackers[.endQueue] = [tracker1, tracker2]
        mocks.environment.app.chartboostAppID = "app123"
        let queue = FullscreenAdQueue.queue(forPlacement: "")

        metricsLogger.logEndQueue(queue)

        for tracker in [tracker1, tracker2] {
            XCTAssertMethodCallPop(
                mocks.networkManagerNew,
                .sendTHTTPRequestWithDecodableResponseHttpRequestTMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithJSONResponseTDecodableResponse,
                parameters: [
                    XCTMethodSomeParameter<EndQueueEventHTTPRequest> { request in
                        XCTAssertEqual(request.url, tracker.url)
                        XCTAssertEqual(request.body.queueID, queue.queueID)
                    },
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter()
                ]
            )
        }
    }

    // MARK: - Container Warning

    func testLogContainerTooSmallWarning_WithTrackers_SendsRequest() {
        let tracker = ServerEventTracker(url: URL(string: "https://example.com/banner-size")!)
        mocks.metricsConfiguration.eventTrackers[.bannerSize] = [tracker]
        let data = AdaptiveBannerSizeData(auctionID: "some auction ID", creativeSize: nil, containerSize: nil, requestSize: nil)

        metricsLogger.logContainerTooSmallWarning(
            adFormat: .adaptiveBanner,
            data: data,
            loadID: "load123"
        )

        XCTAssertMethodCalls(
            mocks.networkManagerNew,
            .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
            parameters: [
                XCTMethodSomeParameter<AdaptiveBannerSizeHTTPRequest> { request in
                    XCTAssertEqual(request.url, tracker.url)
                    XCTAssertEqual(request.body.auctionID, data.auctionID)
                },
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter(),
                XCTMethodIgnoredParameter()
            ]
        )
    }

    func testLogContainerTooSmallWarning_WithoutTrackers_DoesNotSendRequest() {
        mocks.metricsConfiguration.eventTrackers[.bannerSize] = nil
        let data = AdaptiveBannerSizeData(auctionID: "", creativeSize: nil, containerSize: nil, requestSize: nil)

        metricsLogger.logContainerTooSmallWarning(
            adFormat: .adaptiveBanner,
            data: data,
            loadID: "load123"
        )

        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }

    func testLogContainerTooSmallWarning_WithMultipleTrackers_SendsMultipleRequests() {
        let tracker1 = ServerEventTracker(url: URL(string: "https://example.com/banner-size1")!)
        let tracker2 = ServerEventTracker(url: URL(string: "https://example.com/banner-size2")!)
        mocks.metricsConfiguration.eventTrackers[.bannerSize] = [tracker1, tracker2]
        let data = AdaptiveBannerSizeData(auctionID: "", creativeSize: nil, containerSize: nil, requestSize: nil)

        metricsLogger.logContainerTooSmallWarning(
            adFormat: .adaptiveBanner,
            data: data,
            loadID: "load123"
        )

        for tracker in [tracker1, tracker2] {
            XCTAssertMethodCallPop(
                mocks.networkManagerNew,
                .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
                parameters: [
                    XCTMethodSomeParameter<AdaptiveBannerSizeHTTPRequest> { request in
                        XCTAssertEqual(request.url, tracker.url)
                        XCTAssertEqual(request.body.auctionID, data.auctionID)
                    },
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter()
                ]
            )
        }
    }
}

// MARK: - Helpers

extension MetricsEventLoggerTests {

    func assertNetworkingCall(
        trackers: [ServerEventTracker],
        events: [MetricsEvent]? = nil,
        result: String? = nil,
        adFormat: AdFormat? = nil,
        loadID: String? = nil,
        queueID: String? = nil,
        error: ChartboostMediationError? = nil,
        metricsError: ChartboostMediationError? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for tracker in trackers {
            XCTAssertMethodCallPop(
                mocks.networkManagerNew,
                .sendHttpRequestHTTPRequestWithRawDataResponseMaxRetriesIntRetryDelayTimeIntervalCompletionEscapingNetworkManagerRequestCompletionWithRawDataResponse,
                parameters: [
                    XCTMethodSomeParameter<MetricsHTTPRequest> { request in
                        XCTAssertEqual(request.url, tracker.url, file: file, line: line)
                        XCTAssertEqual(request.customHeaders[HTTP.HeaderKey.adType.rawValue], adFormat?.rawValue, file: file, line: line)
                        XCTAssertEqual(request.customHeaders[HTTP.HeaderKey.loadID.rawValue], loadID, file: file, line: line)
                        XCTAssertEqual(request.customHeaders[HTTP.HeaderKey.queueID.rawValue], queueID, file: file, line: line)
                        if let events {
                            XCTAssertEqual(request.body.metrics, events, file: file, line: line)
                        }
                        if let metricsError {
                            XCTAssertEqual(request.body.metrics?.allSatisfy { $0.error?.chartboostMediationCode == metricsError.chartboostMediationCode }, true)
                        }
                        XCTAssertEqual(request.body.result, result, file: file, line: line)
                        XCTAssertEqual(request.body.error?.cmCode, error?.chartboostMediationCode.string, file: file, line: line)
                    },
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter(),
                    XCTMethodIgnoredParameter()
                ],
                file: file,
                line: line
            )
        }
    }

    func assertNoNetworkingCalls(file: StaticString = #file, line: UInt = #line) {
        XCTAssertNoMethodCalls(mocks.networkManagerNew)
    }
}
