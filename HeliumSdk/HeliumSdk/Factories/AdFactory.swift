// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory type to create ads.
protocol AdFactory {
    /// Returns a new Chartboost Mediation fullscreen ad instance.
    func makeFullscreenAd(request: ChartboostMediationAdLoadRequest, winningBidInfo: [String: Any], controller: AdController) -> ChartboostMediationFullscreenAd
    /// Returns a new Helium interstitial ad instance.
    func makeInterstitialAd(placement: String, delegate: CHBHeliumInterstitialAdDelegate?) -> HeliumInterstitialAd
    /// Returns a new Helium rewarded ad instance.
    func makeRewardedAd(placement: String, delegate: CHBHeliumRewardedAdDelegate?) -> HeliumRewardedAd
    /// Returns a new Helium banner ad instance.
    func makeBannerAd(placement: String, size: CHBHBannerSize, delegate: HeliumBannerAdDelegate?) -> HeliumBannerView
}

final class ContainerAdFactory: AdFactory {
    
    @Injected(\.adControllerRepository) private var adControllerRepository
    @Injected(\.adControllerFactory) private var adControllerFactory
    @Injected(\.visibilityTrackerConfiguration) private var visibilityTrackerConfiguration
    
    func makeInterstitialAd(placement: String, delegate: CHBHeliumInterstitialAdDelegate?) -> HeliumInterstitialAd {
        InterstitialAd(
            heliumPlacement: placement,
            delegate: delegate,
            controller: adControllerRepository.adController(forHeliumPlacement: placement)
        )
    }
    
    func makeRewardedAd(placement: String, delegate: CHBHeliumRewardedAdDelegate?) -> HeliumRewardedAd {
        RewardedAd(
            heliumPlacement: placement,
            delegate: delegate,
            controller: adControllerRepository.adController(forHeliumPlacement: placement)
        )
    }
    
    func makeBannerAd(placement: String, size: CHBHBannerSize, delegate: HeliumBannerAdDelegate?) -> HeliumBannerView {
        HeliumBannerView(
            size: size.cgSize,
            controller: makeBannerController(placement: placement, size: size.cgSize, delegate: delegate)
        )
    }
    
    private func makeBannerController(placement: String, size: CGSize, delegate: HeliumBannerAdDelegate?) -> BannerControllerProtocol {
        BannerController(
            heliumPlacement: placement,
            adSize: size,
            delegate: delegate,
            adController: adControllerFactory.makeAdController(),
            visibilityTracker: PixelByTimeVisibilityTracker(configuration: visibilityTrackerConfiguration)
        )
    }
    
    func makeFullscreenAd(request: ChartboostMediationAdLoadRequest, winningBidInfo: [String: Any], controller: AdController) -> ChartboostMediationFullscreenAd {
        FullscreenAd(request: request, winningBidInfo: winningBidInfo, controller: controller)
    }
}
