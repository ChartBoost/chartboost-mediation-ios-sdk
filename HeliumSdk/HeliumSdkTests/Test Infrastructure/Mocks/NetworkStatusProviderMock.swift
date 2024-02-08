// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class NetworkStatusProviderMock: NetworkStatusProviding {
    var status: NetworkStatus = .reachableViaWiFi
}
