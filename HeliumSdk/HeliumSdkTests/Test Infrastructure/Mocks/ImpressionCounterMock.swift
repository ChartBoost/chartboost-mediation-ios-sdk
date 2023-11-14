// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class ImpressionCounterMock: ImpressionCounter {
    var interstitialImpressionCount: Int = 0
    var bannerImpressionCount: Int = 0
    var rewardedImpressionCount: Int = 0
}

extension ImpressionCounterMock {
    func randomizeAll() {
        interstitialImpressionCount = Int.random(in: 0...1000)
        rewardedImpressionCount = Int.random(in: 0...1000)
        bannerImpressionCount = Int.random(in: 0...1000)
    }
}
