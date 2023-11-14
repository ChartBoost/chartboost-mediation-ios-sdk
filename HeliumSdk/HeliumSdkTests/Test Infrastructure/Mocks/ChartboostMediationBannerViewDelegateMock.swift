// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ChartboostMediationBannerViewDelegateMock: Mock<ChartboostMediationBannerViewDelegateMock.Method>, ChartboostMediationBannerViewDelegate {

    enum Method {
        case willAppear
        case didClick
        case didRecordImpression
    }

    func willAppear(bannerView: ChartboostMediationBannerView) {
        record(.willAppear, parameters: [bannerView])
    }

    func didClick(bannerView: ChartboostMediationBannerView) {
        record(.didClick, parameters: [bannerView])
    }

    func didRecordImpression(bannerView: ChartboostMediationBannerView) {
        record(.didRecordImpression, parameters: [bannerView])
    }
}

