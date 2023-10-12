// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

class BannerControllerDelegateMock: Mock<BannerControllerDelegateMock.Method>, BannerControllerDelegate {

    enum Method {
        case displayAd
        case clearAd
        case didRecordImpression
        case didClick
    }

    func bannerController(_ bannerController: ChartboostMediationSDK.BannerControllerProtocol, displayBannerView ad: UIView) {
        record(.displayAd, parameters: [bannerController, ad])
    }

    func bannerController(_ bannerController: ChartboostMediationSDK.BannerControllerProtocol, clearBannerView ad: UIView) {
        record(.clearAd, parameters: [bannerController, ad])
    }

    func bannerControllerDidRecordImpression(_ bannerController: ChartboostMediationSDK.BannerControllerProtocol) {
        record(.didRecordImpression, parameters: [bannerController])
    }

    func bannerControllerDidClick(_ bannerController: ChartboostMediationSDK.BannerControllerProtocol) {
        record(.didClick, parameters: [bannerController])
    }
}
