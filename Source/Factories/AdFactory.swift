// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Factory type to create ads.
protocol AdFactory {
    /// Returns a new Chartboost Mediation fullscreen ad instance.
    func makeFullscreenAd(
        controller: AdController,
        loadedAd: LoadedAd,
        request: FullscreenAdLoadRequest
    ) -> FullscreenAd
    /// Returns a new Chartboost Mediation banner swap controller.
    func makeBannerSwapController() -> BannerSwapControllerProtocol
    /// Returns a new Chartboost Mediation banner controller.
    func makeBannerController(
        request: BannerAdLoadRequest,
        delegate: BannerControllerDelegate?,
        keywords: [String: String]?,
        partnerSettings: [String: Any]?
    ) -> BannerControllerProtocol
}

final class ContainerAdFactory: AdFactory {
    @Injected(\.adControllerRepository) private var adControllerRepository
    @Injected(\.adControllerFactory) private var adControllerFactory
    @Injected(\.visibilityTrackerConfiguration) private var visibilityTrackerConfiguration

    func makeBannerController(
        request: BannerAdLoadRequest,
        delegate: BannerControllerDelegate?,
        keywords: [String: String]?,
        partnerSettings: [String: Any]?
    ) -> BannerControllerProtocol {
        let controller = BannerController(
            request: request,
            adController: adControllerFactory.makeAdController(),
            visibilityTracker: PixelByTimeVisibilityTracker(configuration: visibilityTrackerConfiguration)
        )
        controller.delegate = delegate
        controller.keywords = keywords
        controller.partnerSettings = partnerSettings
        return controller
    }

    func makeBannerSwapController() -> BannerSwapControllerProtocol {
        BannerSwapController()
    }

    func makeFullscreenAd(
        controller: AdController,
        loadedAd: LoadedAd,
        request: FullscreenAdLoadRequest
    ) -> FullscreenAd {
        FullscreenAd(
            request: request,
            winningBidInfo: loadedAd.bidInfo,
            controller: controller,
            loadID: loadedAd.request.loadID
        )
    }
}
