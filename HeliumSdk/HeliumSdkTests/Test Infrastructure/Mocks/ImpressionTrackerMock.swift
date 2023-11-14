// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class ImpressionTrackerMock: Mock<ImpressionTrackerMock.Method>, ImpressionTracker {
    
    enum Method {
        case trackImpression
    }
    
    func trackImpression(for format: AdFormat) {
        record(.trackImpression, parameters: [format])
    }
}
