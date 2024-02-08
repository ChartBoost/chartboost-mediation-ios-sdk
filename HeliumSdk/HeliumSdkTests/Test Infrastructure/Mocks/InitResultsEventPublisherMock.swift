// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

@testable import ChartboostMediationSDK

class InitResultsEventPublisherMock: Mock<InitResultsEventPublisherMock.Method>, InitResultsEventPublisher {
    
    enum Method {
        case postInitResultsEvent
    }
    
    func postInitResultsEvent(_ event: InitResultsEvent) {
        record(.postInitResultsEvent, parameters: [event])
    }
}
