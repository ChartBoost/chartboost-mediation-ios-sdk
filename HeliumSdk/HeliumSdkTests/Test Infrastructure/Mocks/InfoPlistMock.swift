// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// This is just a simple data mock, thus no need to inherit `Mock`.
final class InfoPlistMock: InfoPlistProviding {
    var appVersion: String? = "1.2.3"
    var skAdNetworkIDs: [String] = ["SKAN ID 0", "SKAN ID 2", "SKAN ID 2"]
}
