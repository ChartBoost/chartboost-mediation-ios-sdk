// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK

protocol UserAgentProviding {
    var userAgent: String? { get }
    func updateUserAgent()
}

final class UserAgentProvider: UserAgentProviding {
    private(set) var userAgent: String?

    func updateUserAgent() {
        ChartboostCore.analyticsEnvironment.userAgent { userAgent in
            if let userAgent {
                self.userAgent = userAgent
            }
        }
    }
}
