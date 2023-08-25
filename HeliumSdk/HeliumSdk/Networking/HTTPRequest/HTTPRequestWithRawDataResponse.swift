// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This protocol represents an HTTP request that expects unprocessed `Data?` from the response.
/// The caller is responsible for processing the `Data?` (decode, store, etc).
///
/// This is needed for the overloaded `NetworkManager.send()` functions to work as expected. If
/// `NetworkManager.send()` accepts a `HTTPRequest`, then all request objects comforming to an
/// `HTTPRequest` descendant protocol will be treated as an `HTTPRequest` instead of the specific
/// descendant protocol.
protocol HTTPRequestWithRawDataResponse: HTTPRequest {
    // Intentionally empty so that `HTTPRequestWithRawDataResponse` and `HTTPRequest` are 1:1.
}
