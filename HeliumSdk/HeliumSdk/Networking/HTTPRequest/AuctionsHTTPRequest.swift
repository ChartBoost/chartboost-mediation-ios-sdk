// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// Also known as a "bid request".
struct AuctionsHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithDecodableResponse {

    typealias Body = OpenRTB.BidRequest
    typealias DecodableResponse = OpenRTB.BidResponse

    let method = HTTP.Method.post
    let customHeaders: HTTP.Headers
    let body: Body
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
    let responseKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys

    var url: URL {
        get throws {
            try makeURL(backendAPI: .rtb, path: BackendAPI.Path.RTB.auctions)
        }
    }

    init(bidRequest: OpenRTB.BidRequest, loadRateLimit: Int, loadID: LoadID) {
        customHeaders = [
            HTTP.HeaderKey.loadID.rawValue: loadID,
            HTTP.HeaderKey.rateLimitReset.rawValue: "\(loadRateLimit)"
        ]
        body = bidRequest
    }
}
