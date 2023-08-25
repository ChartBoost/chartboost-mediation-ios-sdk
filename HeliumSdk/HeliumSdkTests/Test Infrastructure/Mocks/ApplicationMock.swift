// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

/// Mocks information provided by `UIApplication` for unit testing purposes.
class ApplicationMock : Mock<ApplicationMock.Method>, Application {
    
    enum Method {
        case addObserver
    }
    
    var state: UIApplication.State = .inactive
    
    func addObserver(_ observer: ApplicationStateObserver) {
        record(.addObserver, parameters: [observer])
    }
}
