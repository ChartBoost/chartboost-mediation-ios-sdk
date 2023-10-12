// Copyright 2022-2023 Chartboost, Inc.
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
        case bannerSize
        case click
        case config // previously known as `sdk_init`
        case expiration
        case initialization
        case load
        case mediationImpression
        case partnerImpression
        case prebid
        case reward
        case show
        case winner

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
                case .bannerSize:
                    return "banner-size"
                case .click:
                    return "click"
                case .config:
                    return "config"
                case .expiration:
                    return "expiration"
                case .initialization:
                    return "initialization"
                case .load:
                    return "load"
                case .mediationImpression:
                    return "mediation-impression"
                case .partnerImpression:
                    return "partner-impression"
                case .prebid:
                    return "prebid"
                case .reward:
                    return "reward"
                case .show:
                    return "show"
                case .winner:
                    return "winner"
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
            case .bannerSize:
                return "/v1/event/banner_size"
            case .click:
                return "/v2/event/click"
            case .config:
                return "/v1/sdk_init"
            case .expiration:
                return "/v1/event/expiration"
            case .initialization:
                return "/v1/event/initialization"
            case .load:
                return "/v2/event/load"
            case .mediationImpression:
                return "/v1/event/helium_impression"
            case .partnerImpression:
                return "/v1/event/partner_impression"
            case .prebid:
                return "/v1/event/prebid"
            case .reward:
                return "/v2/event/reward"
            case .show:
                return "/v1/event/show"
            case .winner:
                return "/v3/event/winner"
            }
        }
    }
}
