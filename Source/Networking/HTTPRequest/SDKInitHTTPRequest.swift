// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

struct SDKInitHTTPRequest: HTTPRequest, HTTPRequestWithRawDataResponse {
    let method = HTTP.Method.get
    let customHeaders: HTTP.Headers
    let isSDKInitializationRequired = false
    private let appID: String

    var url: URL {
        get throws {
            try makeURL(endpoint: .config, extraPathComponents: [appID])
        }
    }

    init(appID: String, deviceOSName: String, deviceOSVersion: String, sdkInitHash: String?, sdkVersion: String) {
        self.appID = appID
        customHeaders = [
            HTTP.HeaderKey.sdkInitHash.rawValue: sdkInitHash,
        ].compactMapValues { $0 }
    }
}
