// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension FullscreenAd {
    /// A convenience factory method to obtain an instance with minimum boilerplate code.
    static func test(
        request: FullscreenAdLoadRequest = .init(placement: "some placement"),
        winningBidInfo: [String: Any] = [:],
        controller: AdController = AdControllerMock(),
        loadID: String = "some load id"
    ) -> FullscreenAd {
        .init(
            request: request,
            winningBidInfo: winningBidInfo,
            controller: controller,
            loadID: loadID
        )
    }
}
