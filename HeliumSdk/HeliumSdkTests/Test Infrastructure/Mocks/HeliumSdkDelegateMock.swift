// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class HeliumSdkDelegateMock: Mock<HeliumSdkDelegateMock.Method>, HeliumSdkDelegate {

    enum Method {
        case didStart
    }

    func heliumDidStartWithError(_ error: ChartboostMediationError?) {
        record(.didStart, parameters: [error])
    }
}
