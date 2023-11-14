// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This protocol represents an HTTP request that expects a JSON in the response body.
protocol HTTPRequestWithDecodableResponse: HTTPRequest {
    associatedtype DecodableResponse: Decodable

    var responseKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy { get }
}
