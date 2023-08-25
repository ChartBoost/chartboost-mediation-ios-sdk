// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

private enum Constant {
    static let defaultURLScheme = "https"
    static let defaultRTBHost = "helium-rtb.chartboost.com"
    static let defaultSDKHost = "helium-sdk.chartboost.com"
}

enum BackendAPI {
    enum Path {
        enum RTB {
            static let auctions = "/v3/auctions"
        }
        enum SDK {
            enum Event {
                static let click = "/v2/event/click"
                static let expiration = "/v1/event/expiration"
                static let heliumImpression = "/v1/event/helium_impression"
                static let initialization = "/v1/event/initialization"
                static let load = "/v1/event/load"
                static let partnerImpression = "/v1/event/partner_impression"
                static let prebid = "/v1/event/prebid"
                static let reward = "/v2/event/reward"
                static let show = "/v1/event/show"
                static let winner = "/v2/event/winner"
            }

            static let sdkInit = "/v1/sdk_init"
        }
    }

    case rtb
    case sdk

    var scheme: String {
        @Injected(\.environment) var environment

        switch self {
        case .rtb:
            return Self.scheme(withHostOverride: environment.testMode.rtbAPIHostOverride)
        case .sdk:
            return Self.scheme(withHostOverride: environment.testMode.sdkAPIHostOverride)
        }
    }

    var host: String {
        @Injected(\.environment) var environment

        switch self {
        case .rtb:
            return Self.host(withHostOverride: environment.testMode.rtbAPIHostOverride, defaultHost: Constant.defaultRTBHost)
        case .sdk:
            return Self.host(withHostOverride: environment.testMode.sdkAPIHostOverride, defaultHost: Constant.defaultSDKHost)
        }
    }
}

extension BackendAPI {
    static func scheme(withHostOverride override: String?, defaultURLScheme: String = Constant.defaultURLScheme) -> String {
        if let override = override, let scheme = URL(string: override)?.scheme {
            return scheme
        } else {
            return defaultURLScheme
        }
    }

    static func host(withHostOverride override: String?, defaultHost: String) -> String {
        if let override = override, let host = URL(string: override)?.host {
            return host
        } else {
            return defaultHost
        }
    }
}
