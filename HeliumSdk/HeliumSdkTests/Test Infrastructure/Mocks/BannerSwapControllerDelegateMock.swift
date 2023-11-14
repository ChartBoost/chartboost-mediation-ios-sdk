// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK
import Foundation

class BannerSwapControllerDelegateMock: Mock<BannerSwapControllerDelegateMock.Method>, BannerSwapControllerDelegate {

    enum Method {
        case displayAd
        case clearAd
        case didRecordImpression
        case didClick
    }

    func bannerSwapController(_ controller: ChartboostMediationSDK.BannerSwapControllerProtocol, displayBannerView ad: UIView) {
        record(.displayAd, parameters: [controller, ad])
    }

    func bannerSwapController(_ controller: ChartboostMediationSDK.BannerSwapControllerProtocol, clearBannerView ad: UIView) {
        record(.clearAd, parameters: [controller, ad])
    }

    func bannerSwapControllerDidRecordImpression(_ controller: ChartboostMediationSDK.BannerSwapControllerProtocol) {
        record(.didRecordImpression, parameters: [controller])
    }

    func bannerSwapControllerDidClick(_ controller: ChartboostMediationSDK.BannerSwapControllerProtocol) {
        record(.didClick, parameters: [controller])
    }
}
