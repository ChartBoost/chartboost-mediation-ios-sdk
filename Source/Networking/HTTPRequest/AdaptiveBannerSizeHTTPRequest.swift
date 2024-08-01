// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Object sent in the body of ``AdaptiveBannerSizeHTTPRequest``.
struct AdaptiveBannerSizeData: Encodable {
    let auctionID: String
    let creativeSize: BackendEncodableSize?
    let containerSize: BackendEncodableSize?
    let requestSize: BackendEncodableSize?
}

/// Error sent when `BannerAdView` is made smaller than the contained ad.
struct AdaptiveBannerSizeHTTPRequest: HTTPRequestWithRawDataResponse, HTTPRequestWithEncodableBody {
    typealias Body = AdaptiveBannerSizeData

    let method = HTTP.Method.post
    let customHeaders: HTTP.Headers
    let body: Body
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase

    var url: URL {
        get throws {
            try makeURL(endpoint: .bannerSize)
        }
    }

    init(adFormat: AdFormat, data: AdaptiveBannerSizeData, loadID: String) {
        body = data
        customHeaders = [
            HTTP.HeaderKey.adType.rawValue: adFormat.rawValue,
            HTTP.HeaderKey.loadID.rawValue: loadID,
        ]
    }
}
