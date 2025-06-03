// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

private enum Constant {
    static let sdkHost = "mediation-sdk.chartboost.com"
}

enum BackendAPI {
    enum Endpoint {
        case auction_nonTracking
        case auction_tracking
        case config // previously known as `sdk_init`
        case load

        var scheme: String {
            "https"
        }

        var host: String {
            var subdomainPrefix: String {
                switch self {
                case .auction_nonTracking:
                    return "non-tracking.auction"
                case .auction_tracking:
                    return "tracking.auction"
                case .config:
                    return "config"
                case .load:
                    return "load"
                }
            }

            @Injected(\.environment) var environment
            let baseHost: String
            if let hostOverride = environment.testMode.sdkAPIHostOverride {
                baseHost = hostOverride.isEmpty ? Constant.sdkHost : hostOverride
            } else {
                baseHost = Constant.sdkHost
            }
            return [subdomainPrefix, baseHost].joined(separator: ".")
        }

        var basePath: String {
            switch self {
            case .auction_nonTracking:
                return "/v3/auctions"
            case .auction_tracking:
                return "/v3/auctions"
            case .config:
                return "/v1/sdk_init"
            case .load:
                return "/v2/event/load"
            }
        }
    }
}
