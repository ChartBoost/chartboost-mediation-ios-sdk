// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol SessionInfoProviding {
    var elapsedSessionDuration: TimeInterval { get }
    var sessionID: UUID { get }
}

struct SessionInfoProvider: SessionInfoProviding {

    let sessionID = UUID()
    let sessionStartDate = Date()

    var elapsedSessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartDate)
    }
}
