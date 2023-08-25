// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class AdFactoryMock: Mock<AdFactoryMock.Method>, AdFactory {
    
    enum Method {
        case makeInterstitialAd
        case makeRewardedAd
        case makeBannerAd
        case makeFullscreenAd
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.makeInterstitialAd: InterstitialAd(
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
            size: .zero,
            controller: BannerControllerMock()
         ),
         .makeFullscreenAd: ChartboostMediationFullscreenAdMock()
        ]
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
}
