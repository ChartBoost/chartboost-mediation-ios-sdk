// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory type to create ads.
protocol AdFactory {
    /// Returns a new Chartboost Mediation fullscreen ad instance.
    func makeFullscreenAd(
        request: ChartboostMediationAdLoadRequest,
        winningBidInfo: [String: Any],
        controller: AdController,
        loadID: String
    ) -> ChartboostMediationFullscreenAd
    /// Returns a new Chartboost Mediation interstitial ad instance.
    func makeInterstitialAd(placement: String, delegate: CHBHeliumInterstitialAdDelegate?) -> HeliumInterstitialAd
    /// Returns a new Chartboost Mediation rewarded ad instance.
    func makeRewardedAd(placement: String, delegate: CHBHeliumRewardedAdDelegate?) -> HeliumRewardedAd
    /// Returns a new Chartboost Mediation banner ad instance.
    func makeBannerAd(placement: String, size: CHBHBannerSize, delegate: HeliumBannerAdDelegate?) -> HeliumBannerView
    /// Returns a new Chartboost Mediation banner swap controller.
    func makeBannerSwapController() -> BannerSwapControllerProtocol
    /// Returns a new Chartboost Mediation banner controller.
    func makeBannerController(
        request: ChartboostMediationBannerLoadRequest,
        delegate: BannerControllerDelegate?,
        keywords: [String: String]?
    ) -> BannerControllerProtocol
}

final class ContainerAdFactory: AdFactory {
    @Injected(\.adControllerRepository) private var adControllerRepository
    @Injected(\.adControllerFactory) private var adControllerFactory
    @Injected(\.visibilityTrackerConfiguration) private var visibilityTrackerConfiguration

    func makeInterstitialAd(placement: String, delegate: CHBHeliumInterstitialAdDelegate?) -> HeliumInterstitialAd {
        InterstitialAd(
            mediationPlacement: placement,
            delegate: delegate,
            controller: adControllerRepository.adController(for: placement)
        )
    }

    func makeRewardedAd(placement: String, delegate: CHBHeliumRewardedAdDelegate?) -> HeliumRewardedAd {
        RewardedAd(
            mediationPlacement: placement,
            delegate: delegate,
            controller: adControllerRepository.adController(for: placement)
        )
    }

    func makeBannerAd(placement: String, size: CHBHBannerSize, delegate: HeliumBannerAdDelegate?) -> HeliumBannerView {
        let requestSize: ChartboostMediationBannerSize

        switch size {
        case .standard: requestSize = .standard
        case .medium: requestSize = .medium
        case .leaderboard: requestSize = .leaderboard
        }

        let request = ChartboostMediationBannerLoadRequest(
            placement: placement,
            size: requestSize
        )

        // The HeliumBannerView will set itself as the delegate of the controller.
        let controller = makeBannerController(request: request, delegate: nil, keywords: nil)

        return HeliumBannerView(
            controller: controller,
            delegate: delegate
        )
    }

    func makeBannerController(
        request: ChartboostMediationBannerLoadRequest,
        delegate: BannerControllerDelegate?,
        keywords: [String: String]?
    ) -> BannerControllerProtocol {
        let controller = BannerController(
            request: request,
            adController: adControllerFactory.makeAdController(),
            visibilityTracker: PixelByTimeVisibilityTracker(configuration: visibilityTrackerConfiguration)
        )
        controller.delegate = delegate
        controller.keywords = keywords
        return controller
    }

    func makeBannerSwapController() -> BannerSwapControllerProtocol {
        BannerSwapController()
    }

    func makeFullscreenAd(
        request: ChartboostMediationAdLoadRequest,
        winningBidInfo: [String: Any],
        controller: AdController,
        loadID: String
    ) -> ChartboostMediationFullscreenAd {
        FullscreenAd(
            request: request,
            winningBidInfo: winningBidInfo,
            controller: controller,
            loadID: loadID
        )
    }
}
