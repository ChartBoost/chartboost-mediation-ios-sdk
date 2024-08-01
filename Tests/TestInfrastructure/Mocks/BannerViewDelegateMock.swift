// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class BannerAdViewDelegateMock: Mock<BannerAdViewDelegateMock.Method>, BannerAdViewDelegate {

    enum Method {
        case willAppear
        case didClick
        case didRecordImpression
    }

    func willAppear(bannerView: BannerAdView) {
        record(.willAppear, parameters: [bannerView])
    }

    func didClick(bannerView: BannerAdView) {
        record(.didClick, parameters: [bannerView])
    }

    func didRecordImpression(bannerView: BannerAdView) {
        record(.didRecordImpression, parameters: [bannerView])
    }
}

