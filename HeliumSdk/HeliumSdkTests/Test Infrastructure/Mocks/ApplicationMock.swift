// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// Mocks information provided by `UIApplication` for unit testing purposes.
class ApplicationMock : Mock<ApplicationMock.Method>, Application {

    enum Method {
        case addObserver
        case removeObserver
    }

    var state: UIApplication.State = .inactive

    func addObserver(_ observer: ApplicationStateObserver) {
        record(.addObserver, parameters: [observer])
    }

    func removeObserver(_ observer: ApplicationStateObserver) {
        record(.removeObserver, parameters: [observer])
    }
}
