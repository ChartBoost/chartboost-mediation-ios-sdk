// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdQueueDelegateMock: Mock<FullscreenAdQueueDelegateMock.Method>, FullscreenAdQueueDelegate {

    enum Method {
        case didRemoveExpiredAd
        case didFinishLoadingWithResult
    }

    func fullscreenAdQueueDidRemoveExpiredAd(_ adQueue: FullscreenAdQueue, numberOfAdsReady: Int) {
        record(.didRemoveExpiredAd, parameters: [adQueue, numberOfAdsReady])
    }

    func fullscreenAdQueue(_ adQueue: FullscreenAdQueue, didFinishLoadingWithResult result: AdLoadResult, numberOfAdsReady: Int) {
        record(.didFinishLoadingWithResult, parameters: [adQueue, result, numberOfAdsReady])
    }
}
