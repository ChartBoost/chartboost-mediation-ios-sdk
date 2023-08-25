// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppTrackingTransparency
@testable import ChartboostMediationSDK

/// This is just a simple data mock, thus no need to inherit `Mock`.
final class AppTrackingInfoProviderMock: AppTrackingInfoProviding {
    var appTransparencyAuthStatus: UInt?
    var idfa: String?
    var idfv: String?
    var isLimitAdTrackingEnabled = false
}
