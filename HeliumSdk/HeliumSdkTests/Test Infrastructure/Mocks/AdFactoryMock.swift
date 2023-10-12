// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdFactoryMock: Mock<AdFactoryMock.Method>, AdFactory {

    enum Error: Swift.Error {
        case NoBannerControllers
    }

    enum Method {
        case makeInterstitialAd
        case makeRewardedAd
        case makeBannerAd
        case makeFullscreenAd
        case makeBannerController
        case makeBannerSwapController
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [
            .makeInterstitialAd: InterstitialAd(
                heliumPlacement: "",
                delegate: HeliumInterstitialAdDelegateMock(),
                controller: AdControllerMock()
            ),
            .makeRewardedAd: InterstitialAd(
                heliumPlacement: "",
                delegate: HeliumInterstitialAdDelegateMock(),
                controller: AdControllerMock()
            ),
            .makeBannerAd: HeliumBannerView(
                controller: BannerControllerMock(),
                delegate: nil
            ),
            .makeFullscreenAd: ChartboostMediationFullscreenAdMock(),
            .makeBannerController: BannerControllerMock(),
            .makeBannerSwapController: BannerSwapControllerMock()
        ]
    }

    private var bannerControllers: [ChartboostMediationSDK.BannerControllerProtocol] = []

    override func removeAllRecords() {
        super.removeAllRecords()
        bannerControllers.removeAll()
    }

    /// Call to pop the oldest created `BannerController` off the stack.
    func popBannerController() throws -> ChartboostMediationSDK.BannerControllerProtocol {
        guard bannerControllers.count > 0 else {
            throw Error.NoBannerControllers
        }

        return bannerControllers.removeFirst()
    }
    
    func makeInterstitialAd(placement: String, delegate: CHBHeliumInterstitialAdDelegate?) -> HeliumInterstitialAd {
        record(.makeInterstitialAd, parameters: [placement, delegate])
    }
    
    func makeRewardedAd(placement: String, delegate: CHBHeliumRewardedAdDelegate?) -> HeliumRewardedAd {
        record(.makeRewardedAd, parameters: [placement, delegate])
    }
    
    func makeBannerAd(placement: String, size: CHBHBannerSize, delegate: HeliumBannerAdDelegate?) -> HeliumBannerView {
        record(.makeBannerAd, parameters: [placement, size, delegate])
    }
    
    func makeFullscreenAd(request: ChartboostMediationAdLoadRequest, winningBidInfo: [String : Any], controller: AdController) -> ChartboostMediationFullscreenAd {
        record(.makeFullscreenAd, parameters: [request, winningBidInfo, controller])
    }

    func makeBannerController(request: ChartboostMediationSDK.ChartboostMediationBannerLoadRequest, delegate: ChartboostMediationSDK.BannerControllerDelegate?, keywords: [String : String]?) -> ChartboostMediationSDK.BannerControllerProtocol {
        record(.makeBannerController, parameters: [request])

        // Save the controllers in a stack for `BannerSwapControllerTests`, where we need to:
        //   * Track states across multiple `BannerControllerMock` instances.
        //   * Ensure the `BannerControllerMock` was created with the correct request.
        let controller = BannerControllerMock(request: request)
        controller.delegate = delegate
        controller.keywords = keywords
        bannerControllers.append(controller)
        return controller
    }

    func makeBannerSwapController() -> ChartboostMediationSDK.BannerSwapControllerProtocol {
        record(.makeBannerSwapController, parameters: [])
    }
}
