// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class FullscreenAdQueueConfigurationMock: Mock<FullscreenAdQueueConfigurationMock.Method>, FullscreenAdQueueConfiguration {
    enum Method {
        case queueSize
    }

    override var  defaultReturnValues: [Method : Any?] {
        [.queueSize: 5]
    }

    var maxQueueSize: Int = 5
    var defaultQueueSize: Int = 5
    var queuedAdTtl: TimeInterval = 2
    var queueLoadTimeout: TimeInterval = 1
    func queueSize(for placement: String) -> Int {
        record(.queueSize, parameters: [placement])
    }
}
