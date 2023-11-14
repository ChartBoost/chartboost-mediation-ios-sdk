// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK

class ReachabilityMock: Reachability {
    var status: NetworkStatus = .reachableViaWiFi

    @discardableResult func startNotifier() -> Bool {
        true
    }

    func stopNotifier() {
        
    }
}
