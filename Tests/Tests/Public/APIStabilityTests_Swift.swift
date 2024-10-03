// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostMediationSDK
import XCTest

/// This is a compile time test, not a runtime test.
/// The tests pass as long as everything compiles without errors.
class APIStabilityTests_Swift: ChartboostMediationTestCase {

    func stability_FullscreenAdLoadRequest() {
        var target = FullscreenAdLoadRequest(placement: "")
        target = FullscreenAdLoadRequest(placement: "", keywords: ["": ""])
        let _: String = target.placement
        let _: [String: String] = target.keywords
    }

    func stability_AdLoadResult() throws {
        let target: AdLoadResult = try XCTUnwrap(nil as AdLoadResult?)
        let _: ChartboostMediationError? = target.error
        let _: String = target.loadID
        let _: [String: Any]? = target.metrics
    }

    func stability_AdShowResult() throws {
        let target: AdShowResult = try XCTUnwrap(nil as AdShowResult?)
        let _: ChartboostMediationError? = target.error
        let _: [String: Any]? = target.metrics
    }

    func stability_BannerAdLoadRequest() {
        let target = BannerAdLoadRequest(placement: "", size: .standard)
        let _: String = target.placement
        let _: BannerSize = target.size
    }

    func stability_BannerAdLoadResult() throws {
        let target: BannerAdLoadResult = try XCTUnwrap(nil as BannerAdLoadResult?)
        let _: BannerSize? = target.size
    }

    func stability_BannerAdView() {
        var target: BannerAdView = .init()
        target = .init(frame: .zero)
        let _: BannerAdViewDelegate? = target.delegate
        target.delegate = Mock.bannerViewDelegate
        let _: [String: String]? = target.keywords
        let _: BannerHorizontalAlignment = target.horizontalAlignment
        let _: BannerVerticalAlignment = target.verticalAlignment
        let _: BannerAdLoadRequest? = target.request
        let _: [String: Any]? = target.loadMetrics
        let _: BannerSize? = target.size
        let _: [String: Any]? = target.winningBidInfo
        target.load(with: .init(placement: "", size: .standard), viewController: UIViewController()) { bannerAdLoadResult in
            let _:BannerAdLoadResult = bannerAdLoadResult
        }
        target.reset()
    }

    func stability_BannerHorizontalAlignment() {
        let _: [BannerHorizontalAlignment] = [.left, .center, .right]
    }

    func stability_BannerSize() {
        var target: BannerSize = .standard
        target = .medium
        target = .leaderboard
        target = .adaptive(width: CGFloat(0.1))
        target = .adaptive(width: CGFloat(0.1), maxHeight: CGFloat(0.1))
        target = .adaptive1x1(width: CGFloat(0.1))
        target = .adaptive1x2(width: CGFloat(0.1))
        target = .adaptive1x3(width: CGFloat(0.1))
        target = .adaptive1x4(width: CGFloat(0.1))
        target = .adaptive2x1(width: CGFloat(0.1))
        target = .adaptive4x1(width: CGFloat(0.1))
        target = .adaptive6x1(width: CGFloat(0.1))
        target = .adaptive8x1(width: CGFloat(0.1))
        target = .adaptive10x1(width: CGFloat(0.1))
        target = .adaptive9x16(width: CGFloat(0.1))
        let _: CGSize = target.size
        let _: BannerType = target.type
        let _: CGFloat = target.aspectRatio
    }

    func stability_BannerType() {
        let _: [BannerType] = [.adaptive, .fixed]
    }

    func stability_BannerVerticalAlignment() {
        let _: [BannerVerticalAlignment] = [.top, .center, .bottom]
    }

    func stability_ChartboostMediation() {
        ChartboostMediation.setPreinitializationConfiguration(nil) // ignore return value
        let _: ChartboostMediationError? = ChartboostMediation.setPreinitializationConfiguration(
            PreinitializationConfiguration(skippedPartnerIDs: [""])
        )

        ChartboostMediation.logLevel = .disabled

        let _: String = ChartboostMediation.sdkVersion
        let _: [PartnerAdapterInfo] = ChartboostMediation.initializedAdapterInfo
        let _: Bool = ChartboostMediation.discardOversizedAds
        let _: Bool = ChartboostMediation.isTestModeEnabled
        ChartboostMediation.isTestModeEnabled = false
    }

    func stability_ChartboostMediationError() throws {
        let error: ChartboostMediationError = try XCTUnwrap(nil as ChartboostMediationError?)
        let errorCode: ChartboostMediationError.Code = error.chartboostMediationCode
        let _: String = error.localizedDescription
        let _: String = errorCode.cause
        let _: String = errorCode.message
        let _: String = errorCode.name
        let _: String = errorCode.resolution
        let _: String = errorCode.string

        let _: ChartboostMediationError.Code.Group = errorCode.group
        let _: ChartboostMediationError.Code.Group = .initialization // 100
        let _: ChartboostMediationError.Code.Group = .prebid // 200
        let _: ChartboostMediationError.Code.Group = .load // 300
        let _: ChartboostMediationError.Code.Group = .show // 400
        let _: ChartboostMediationError.Code.Group = .invalidate // 500
        let _: ChartboostMediationError.Code.Group = .others // 600

        let _: ChartboostMediationError.Code = .initializationFailureUnknown // 100
        let _: ChartboostMediationError.Code = .initializationFailureAborted // 101
        let _: ChartboostMediationError.Code = .initializationFailureAdBlockerDetected // 102
        let _: ChartboostMediationError.Code = .initializationFailureAdapterNotFound // 103
        let _: ChartboostMediationError.Code = .initializationFailureInvalidAppConfig // 104
        let _: ChartboostMediationError.Code = .initializationFailureInvalidCredentials // 105
        let _: ChartboostMediationError.Code = .initializationFailureNoConnectivity // 106
        let _: ChartboostMediationError.Code = .initializationFailurePartnerNotIntegrated // 107
        let _: ChartboostMediationError.Code = .initializationFailureTimeout // 108
        let _: ChartboostMediationError.Code = .initializationSkipped // 109
        let _: ChartboostMediationError.Code = .initializationFailureException // 110
        let _: ChartboostMediationError.Code = .initializationFailureViewControllerNotFound // 111
        let _: ChartboostMediationError.Code = .initializationFailureNetworkingError // 112
        let _: ChartboostMediationError.Code = .initializationFailureOSVersionNotSupported // 113
        let _: ChartboostMediationError.Code = .initializationFailureServerError // 114
        let _: ChartboostMediationError.Code = .initializationFailureInternalError // 115
        let _: ChartboostMediationError.Code = .initializationFailureInitializationInProgress // 116
        let _: ChartboostMediationError.Code = .initializationFailureInitializationDisabled // 117

        let _: ChartboostMediationError.Code = .prebidFailureUnknown // 200
        let _: ChartboostMediationError.Code = .prebidFailureAdapterNotFound // 201
        let _: ChartboostMediationError.Code = .prebidFailureInvalidArgument // 202
        let _: ChartboostMediationError.Code = .prebidFailureNotInitialized // 203
        let _: ChartboostMediationError.Code = .prebidFailurePartnerNotIntegrated // 204
        let _: ChartboostMediationError.Code = .prebidFailureTimeout // 205
        let _: ChartboostMediationError.Code = .prebidFailureException // 206
        let _: ChartboostMediationError.Code = .prebidFailureOSVersionNotSupported // 207
        let _: ChartboostMediationError.Code = .prebidFailureNetworkingError // 208

        let _: ChartboostMediationError.Code = .loadFailureUnknown // 300
        let _: ChartboostMediationError.Code = .loadFailureAborted // 301
        let _: ChartboostMediationError.Code = .loadFailureAdBlockerDetected // 302
        let _: ChartboostMediationError.Code = .loadFailureAdapterNotFound // 303
        let _: ChartboostMediationError.Code = .loadFailureAuctionNoBid // 304
        let _: ChartboostMediationError.Code = .loadFailureAuctionTimeout // 305
        let _: ChartboostMediationError.Code = .loadFailureInvalidAdMarkup // 306
        let _: ChartboostMediationError.Code = .loadFailureInvalidAdRequest // 307
        let _: ChartboostMediationError.Code = .loadFailureInvalidBidResponse // 308
        let _: ChartboostMediationError.Code = .loadFailureInvalidChartboostMediationPlacement // 309
        let _: ChartboostMediationError.Code = .loadFailureInvalidPartnerPlacement // 310
        let _: ChartboostMediationError.Code = .loadFailureMismatchedAdFormat // 311
        let _: ChartboostMediationError.Code = .loadFailureNoConnectivity // 312
        let _: ChartboostMediationError.Code = .loadFailureNoFill // 313
        let _: ChartboostMediationError.Code = .loadFailurePartnerNotInitialized // 314
        let _: ChartboostMediationError.Code = .loadFailureOutOfStorage // 315
        let _: ChartboostMediationError.Code = .loadFailurePartnerNotIntegrated // 316
        let _: ChartboostMediationError.Code = .loadFailureRateLimited // 317
        let _: ChartboostMediationError.Code = .loadFailureShowInProgress // 318
        let _: ChartboostMediationError.Code = .loadFailureTimeout // 319
        let _: ChartboostMediationError.Code = .loadFailureUnsupportedAdFormat // 320
        let _: ChartboostMediationError.Code = .loadFailurePrivacyOptIn // 321
        let _: ChartboostMediationError.Code = .loadFailurePrivacyOptOut // 322
        let _: ChartboostMediationError.Code = .loadFailurePartnerInstanceNotFound // 323
        let _: ChartboostMediationError.Code = .loadFailureMismatchedAdParams // 324
        let _: ChartboostMediationError.Code = .loadFailureInvalidBannerSize // 325
        let _: ChartboostMediationError.Code = .loadFailureException // 326
        let _: ChartboostMediationError.Code = .loadFailureLoadInProgress // 327
        let _: ChartboostMediationError.Code = .loadFailureViewControllerNotFound // 328
        let _: ChartboostMediationError.Code = .loadFailureNoBannerView // 329
        let _: ChartboostMediationError.Code = .loadFailureNetworkingError // 330
        let _: ChartboostMediationError.Code = .loadFailureChartboostMediationNotInitialized // 331
        let _: ChartboostMediationError.Code = .loadFailureOSVersionNotSupported // 332
        let _: ChartboostMediationError.Code = .loadFailureServerError // 333
        let _: ChartboostMediationError.Code = .loadFailureInvalidCredentials // 334
        let _: ChartboostMediationError.Code = .loadFailureWaterfallExhaustedNoFill // 335
        let _: ChartboostMediationError.Code = .loadFailureAdTooLarge // 336

        let _: ChartboostMediationError.Code = .showFailureUnknown // 400
        let _: ChartboostMediationError.Code = .showFailureViewControllerNotFound // 401
        let _: ChartboostMediationError.Code = .showFailureAdBlockerDetected // 402
        let _: ChartboostMediationError.Code = .showFailureAdNotFound // 403
        let _: ChartboostMediationError.Code = .showFailureAdExpired // 404
        let _: ChartboostMediationError.Code = .showFailureAdNotReady // 405
        let _: ChartboostMediationError.Code = .showFailureAdapterNotFound // 406
        let _: ChartboostMediationError.Code = .showFailureInvalidChartboostMediationPlacement // 407
        let _: ChartboostMediationError.Code = .showFailureInvalidPartnerPlacement // 408
        let _: ChartboostMediationError.Code = .showFailureMediaBroken // 409
        let _: ChartboostMediationError.Code = .showFailureNoConnectivity // 410
        let _: ChartboostMediationError.Code = .showFailureNoFill // 411
        let _: ChartboostMediationError.Code = .showFailureNotInitialized // 412
        let _: ChartboostMediationError.Code = .showFailureNotIntegrated // 413
        let _: ChartboostMediationError.Code = .showFailureShowInProgress // 414
        let _: ChartboostMediationError.Code = .showFailureTimeout // 415
        let _: ChartboostMediationError.Code = .showFailureVideoPlayerError // 416
        let _: ChartboostMediationError.Code = .showFailurePrivacyOptIn // 417
        let _: ChartboostMediationError.Code = .showFailurePrivacyOptOut // 418
        let _: ChartboostMediationError.Code = .showFailureWrongResourceType // 419
        let _: ChartboostMediationError.Code = .showFailureUnsupportedAdType // 420
        let _: ChartboostMediationError.Code = .showFailureException // 421
        let _: ChartboostMediationError.Code = .showFailureUnsupportedAdSize // 422
        let _: ChartboostMediationError.Code = .showFailureInvalidBannerSize // 423

        let _: ChartboostMediationError.Code = .invalidateFailureUnknown // 500
        let _: ChartboostMediationError.Code = .invalidateFailureAdNotFound // 501
        let _: ChartboostMediationError.Code = .invalidateFailureAdapterNotFound // 502
        let _: ChartboostMediationError.Code = .invalidateFailureNotInitialized // 503
        let _: ChartboostMediationError.Code = .invalidateFailurePartnerNotIntegrated // 504
        let _: ChartboostMediationError.Code = .invalidateFailureTimeout // 505
        let _: ChartboostMediationError.Code = .invalidateFailureWrongResourceType // 506
        let _: ChartboostMediationError.Code = .invalidateFailureException // 507

        let _: ChartboostMediationError.Code = .unknown // 600
        let _: ChartboostMediationError.Code = .partnerError // 601
        let _: ChartboostMediationError.Code = .internal // 602
        let _: ChartboostMediationError.Code = .noConnectivity // 603
        let _: ChartboostMediationError.Code = .adServerError // 604
        let _: ChartboostMediationError.Code = .invalidArguments // 605
        let _: ChartboostMediationError.Code = .preinitializationActionFailed // 606
    }

    func stability_FullscreenAd() throws {
        let target: FullscreenAd = try XCTUnwrap(nil as FullscreenAd?)
        let _: FullscreenAdDelegate? = target.delegate
        target.delegate = Mock.fullscreenAdDelegate
        let _: String? = target.customData
        let _: String = target.loadID
        let _: FullscreenAdLoadRequest = target.request
        let _: [String: Any] = target.winningBidInfo
        target.show(with: UIViewController()) { adShowResult in
            let _: AdShowResult = adShowResult
        }
        target.invalidate()
        FullscreenAd.load(with: FullscreenAdLoadRequest(placement: "")) { result in
            let _: FullscreenAdLoadResult = result
        }
    }

    func stability_FullscreenAdLoadResult() throws {
        let target: FullscreenAdLoadResult = try XCTUnwrap(nil as FullscreenAdLoadResult?)
        let _: FullscreenAd? = target.ad
        let _: ChartboostMediationError? = target.error
        let _: String = target.loadID
        let _: [String: Any]? = target.metrics
    }

    func stability_FullscreenAdQueue() {
        let target: FullscreenAdQueue = FullscreenAdQueue.queue(forPlacement: "")
        let _: FullscreenAdQueueDelegate? = target.delegate
        target.delegate = Mock.fullscreenAdQueueDelegate
        let _: Bool = target.hasNextAd
        let _: Bool = target.isRunning
        let _: [String: String] = target.keywords
        let _: Int = target.numberOfAdsReady
        let _: String = target.placement
        let _: Int = target.queueCapacity
        let _: FullscreenAd? = target.getNextAd()
        target.setQueueCapacity(Int(1))
        target.start()
        target.stop()
    }

    func stability_ImpressionData() throws {
        let target: ImpressionData = try XCTUnwrap(nil as ImpressionData?)
        let _: String = target.placement
        let _: [String: Any] = target.jsonData
    }

    func stability_Notifications() {
        NotificationCenter.default.addObserver(
            forName: .chartboostMediationDidReceiveILRD,
            object: nil,
            queue: nil
        ) { _ in }

        NotificationCenter.default.addObserver(
            forName: .chartboostMediationDidReceivePartnerAdapterInitResults,
            object: nil,
            queue: nil
        ) { _ in }
    }

    func stability_PartnerAd() {
        let target = Mock.partnerAd

        // Error
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?, error: nil as Error?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, error: nil as Error?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError)
        let _: Error = target.partnerError(Int(1))
        let _: Error = target.partnerError(Int(1), description: nil as String?)

        // Log
        target.log(PartnerAdLogEvent.loadStarted)
        target.log(PartnerAdLogEvent.init(stringLiteral: ""))
        target.log(PartnerAdLogEvent.init(stringInterpolation: .init(literalCapacity: 1, interpolationCount: 1)))
    }

    func stability_PartnerAdapter() {
        let target = Mock.partnerAdapter

        // Error factory
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?, error: nil as Error?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError, error: nil as Error?)
        let _: Error = target.error(ChartboostMediationError.Code.adServerError)
        let _: Error = target.partnerError(Int(1))
        let _: Error = target.partnerError(Int(1), description: nil as String?)

        // Error mapping
        let _: ChartboostMediationError.Code? = target.mapLoadError(NSError(domain: "", code: 1))
        let _: ChartboostMediationError.Code? = target.mapShowError(NSError(domain: "", code: 1))
        let _: ChartboostMediationError.Code? = target.mapPrebidError(NSError(domain: "", code: 1))
        let _: ChartboostMediationError.Code? = target.mapSetUpError(NSError(domain: "", code: 1))
        let _: ChartboostMediationError.Code? = target.mapPrebidError(NSError(domain: "", code: 1))

        // Log
        target.log(PartnerLogEvent.setUpStarted)
        target.log(PartnerLogEvent.init(stringLiteral: ""))
        target.log(PartnerLogEvent.init(stringInterpolation: .init(literalCapacity: 1, interpolationCount: 1)))
    }

    func stability_PartnerAdapterInfo() throws {
        let target: PartnerAdapterInfo = try XCTUnwrap(nil as PartnerAdapterInfo?)
        let _: String = target.adapterVersion
        let _: String = target.partnerVersion
        let _: String = target.partnerDisplayName
        let _: String = target.partnerID
    }

    func stability_PartnerAdFormat() {
        let _: [PartnerAdFormat] = [
            PartnerAdFormats.banner,
            PartnerAdFormats.interstitial,
            PartnerAdFormats.rewarded,
            PartnerAdFormats.rewardedInterstitial
        ]
    }

    func stability_PartnerAdLoadRequest() throws {
        let target: PartnerAdLoadRequest = try XCTUnwrap(nil as PartnerAdLoadRequest?)
        let _: String = target.partnerID
        let _: String = target.mediationPlacement
        let _: String = target.partnerPlacement
        let _: PartnerAdFormat = target.format
        let _: BannerSize? = target.bannerSize
        let _: String? = target.adm
        let _: [String: String] = target.keywords
        let _: [String: Any] = target.partnerSettings
        let _: String = target.identifier
    }

    func stability_PartnerAdLogEvent() {
        let error: Error = NSError()
        let _: PartnerAdLogEvent = .loadStarted
        let _: PartnerAdLogEvent = .loadSucceeded
        let _: PartnerAdLogEvent = .loadFailed(error)
        let _: PartnerAdLogEvent = .loadResultIgnored
        let _: PartnerAdLogEvent = .invalidateStarted
        let _: PartnerAdLogEvent = .invalidateSucceeded
        let _: PartnerAdLogEvent = .invalidateFailed(error)
        let _: PartnerAdLogEvent = .showStarted
        let _: PartnerAdLogEvent = .showSucceeded
        let _: PartnerAdLogEvent = .showFailed(error)
        let _: PartnerAdLogEvent = .showResultIgnored
        let _: PartnerAdLogEvent = .didTrackImpression
        let _: PartnerAdLogEvent = .didClick(error: nil as Error?)
        let _: PartnerAdLogEvent = .didReward
        let _: PartnerAdLogEvent = .didDismiss(error: nil as Error?)
        let _: PartnerAdLogEvent = .didExpire
        let _: PartnerAdLogEvent = .delegateUnavailable
        let _: PartnerAdLogEvent = .delegateCallIgnored
        let _: PartnerAdLogEvent = .custom("")
    }

    func stability_PartnerConfiguration() throws {
        let target: PartnerConfiguration = try XCTUnwrap(nil as PartnerConfiguration?)
        let _: [String: Any] = target.credentials
    }

    func stability_PartnerLogEvent() throws {
        let prebidRequest: PartnerAdPreBidRequest = try XCTUnwrap(nil as PartnerAdPreBidRequest?)
        let error: Error = NSError()
        let _: PartnerLogEvent = .setUpStarted
        let _: PartnerLogEvent = .setUpSucceded
        let _: PartnerLogEvent = .setUpFailed(error)
        let _: PartnerLogEvent = .fetchBidderInfoStarted(prebidRequest)
        let _: PartnerLogEvent = .fetchBidderInfoSucceeded(prebidRequest)
        let _: PartnerLogEvent = .fetchBidderInfoFailed(prebidRequest, error: error)
        let _: PartnerLogEvent = .fetchBidderInfoNotSupported
        let _: PartnerLogEvent = .privacyUpdated(setting: "", value: nil as Any?)
        let _: PartnerLogEvent = .custom("")
    }

    func stability_PartnerAdPreBidRequest() throws {
        let target: PartnerAdPreBidRequest = try XCTUnwrap(nil as PartnerAdPreBidRequest?)
        let _: String = target.mediationPlacement
        let _: PartnerAdFormat = target.format
        let _: BannerSize? = target.bannerSize
        let _: [String: Any] = target.partnerSettings
        let _: [String: String] = target.keywords
    }

    func stability_PartnerBannerSize() throws {
        let size = PartnerBannerSize(size: CGSize(width: 100, height: 50), type: .fixed)
        let _: CGSize = size.size
        let _: BannerType = size.type
    }

    func stability_PartnerErrorFactory() throws {
        let target: PartnerErrorFactory? = nil
        if let target {
            let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?)
            let _: Error = target.error(ChartboostMediationError.Code.adServerError, description: nil as String?, error: nil as Error?)
            let _: Error = target.error(ChartboostMediationError.Code.adServerError, error: nil as Error?)
            let _: Error = target.error(ChartboostMediationError.Code.adServerError)
            let _: Error = target.partnerError(Int(1))
            let _: Error = target.partnerError(Int(1), description: nil as String?)
        }
    }

    func stability_PartnerErrorMapping() throws {
        let target: PartnerErrorMapping? = nil
        if let target {
            let _: ChartboostMediationError.Code? = target.mapLoadError(NSError(domain: "", code: 1))
            let _: ChartboostMediationError.Code? = target.mapShowError(NSError(domain: "", code: 1))
            let _: ChartboostMediationError.Code? = target.mapPrebidError(NSError(domain: "", code: 1))
            let _: ChartboostMediationError.Code? = target.mapSetUpError(NSError(domain: "", code: 1))
            let _: ChartboostMediationError.Code? = target.mapPrebidError(NSError(domain: "", code: 1))
        }
    }

    func stability_PreinitializationConfiguration() throws {
        let target: PreinitializationConfiguration = .init(skippedPartnerIDs: [""])
        let _: Set<PartnerID> = target.skippedPartnerIDs
    }
}

// MARK: - Protocol Stability

extension APIStabilityTests_Swift: BannerAdViewDelegate {
    enum Mock {

        // MARK: - BannerAdViewDelegate

        static let bannerViewDelegate = BannerAdViewDelegateMock()
        class BannerAdViewDelegateMock: BannerAdViewDelegate {
            func didClick(bannerView: BannerAdView) {}
            func didRecordImpression(bannerView: BannerAdView) {}
            func willAppear(bannerView: BannerAdView) {}
        }

        class BannerAdViewDelegateMock_minimum: BannerAdViewDelegate {
            // optional funcs are not implemented
        }

        // MARK: - FullscreenAdDelegate

        static let fullscreenAdDelegate = FullscreenAdDelegateMock()
        class FullscreenAdDelegateMock: FullscreenAdDelegate {
            func didClick(ad: FullscreenAd) {}
            func didClose(ad: FullscreenAd, error: ChartboostMediationError?) {}
            func didExpire(ad: FullscreenAd) {}
            func didRecordImpression(ad: FullscreenAd) {}
            func didReward(ad: FullscreenAd) {}
        }

        class FullscreenAdDelegateMock_minimum: FullscreenAdDelegate {
            // optional funcs are not implemented
        }

        // MARK: - FullscreenAdQueueDelegate

        static let fullscreenAdQueueDelegate = FullscreenAdQueueDelegateMock()
        class FullscreenAdQueueDelegateMock: FullscreenAdQueueDelegate {
            func fullscreenAdQueue(_ adQueue: FullscreenAdQueue, didFinishLoadingWithResult result: AdLoadResult, numberOfAdsReady: Int) {}
            func fullscreenAdQueueDidRemoveExpiredAd(_ adQueue: FullscreenAdQueue, numberOfAdsReady: Int) {}
        }

        class FullscreenAdQueueDelegateMock_minimum: FullscreenAdQueueDelegate {
            // optional funcs are not implemented
        }

        // MARK: - PartnerAd

        static let partnerAd = PartnerAdMock()
        class PartnerAdMock: PartnerAd {
            var adapter: PartnerAdapter { fatalError() }
            var request: PartnerAdLoadRequest { fatalError() }
            var delegate: PartnerAdDelegate? { nil }
            var details: PartnerDetails { [:] }
            func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {}
            func invalidate() throws { fatalError() }
        }

        // MARK: - PartnerAdapter

        static let partnerAdapter = PartnerAdapterMock(storage: Mock.partnerAdapterStorage)
        class PartnerAdapterMock: PartnerAdapter {
            var configuration: PartnerAdapterConfiguration.Type { fatalError() }
            required init(storage: PartnerAdapterStorage) { fatalError() }
            func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {}
            func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd { fatalError() }
            func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd { fatalError() }
            func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {}
            func setIsUserUnderage(_ isUserUnderage: Bool) {}
            func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {}
        }

        // MARK: - PartnerAdapterConfiguration

        static let partnerAdapterConfiguration = PartnerAdapterConfigurationMock()
        class PartnerAdapterConfigurationMock: NSObject, PartnerAdapterConfiguration {
            static var adapterVersion: String { "" }
            static var partnerDisplayName: String { "" }
            static var partnerID: String { "" }
            static var partnerSDKVersion: String { "" }
        }

        // MARK: - PartnerAdapterStorage

        static let partnerAdapterStorage = PartnerAdapterStorageMock()
        class PartnerAdapterStorageMock: PartnerAdapterStorage {
            var ads: [PartnerAd] { [] }
        }

        // MARK: - PartnerAdDelegate

        static let partnerAdDelegate = PartnerAdDelegateMock()
        class PartnerAdDelegateMock: PartnerAdDelegate {
            func didClick(_ ad: PartnerAd) {}
            func didDismiss(_ ad: PartnerAd, error: Error?) {}
            func didExpire(_ ad: PartnerAd) {}
            func didReward(_ ad: PartnerAd) {}
            func didTrackImpression(_ ad: PartnerAd) {}
        }

        // MARK: - PartnerBannerAd

        static let partnerBannerAd = PartnerBannerAdMock()
        class PartnerBannerAdMock: PartnerBannerAd {
            var adapter: PartnerAdapter { fatalError() }
            var request: PartnerAdLoadRequest { fatalError() }
            var delegate: PartnerAdDelegate? { nil }
            var view: UIView? { nil }
            var size: PartnerBannerSize? { nil }
            var details: PartnerDetails { [:] }
            func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {}
            func invalidate() throws { fatalError() }
        }

        // MARK: - PartnerErrorFactory

        class PartnerErrorFactoryMock: PartnerErrorFactory {
            func error(_ code: ChartboostMediationError.Code) -> Error { fatalError() }
            func error(_ code: ChartboostMediationError.Code, description: String?) -> Error { fatalError() }
            func error(_ code: ChartboostMediationError.Code, error: Error?) -> Error { fatalError() }
            func error(_ code: ChartboostMediationError.Code, description: String?, error: Error?) -> Error { fatalError() }
            func partnerError(_ code: Int) -> Error { fatalError() }
            func partnerError(_ code: Int, description: String?) -> Error { fatalError() }
        }

        // MARK: - PartnerErrorMapping

        class PartnerErrorMappingMock: PartnerErrorMapping {
            func mapSetUpError(_ error: any Error) -> ChartboostMediationError.Code? { nil }
            func mapPrebidError(_ error: any Error) -> ChartboostMediationError.Code? { nil }
            func mapLoadError(_ error: any Error) -> ChartboostMediationError.Code? { nil }
            func mapShowError(_ error: any Error) -> ChartboostMediationError.Code? { nil }
            func mapInvalidateError(_ error: any Error) -> ChartboostMediationError.Code? { nil }
        }

        // MARK: - PartnerFullscreenAd

        static let partnerFullscreenAd = PartnerFullscreenAdMock()
        class PartnerFullscreenAdMock: PartnerFullscreenAd {
            var adapter: PartnerAdapter { fatalError() }
            var request: PartnerAdLoadRequest { fatalError() }
            var delegate: PartnerAdDelegate? { nil }
            var details: PartnerDetails { [:] }
            func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {}
            func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {}
            func invalidate() throws { fatalError() }
        }
    }
}
