// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// An HTTP constant container.
enum HTTP {
    typealias Headers = [String: String]
    typealias StatusCode = Int

    enum Method: String, CaseIterable, CustomStringConvertible {
        case get = "GET"
        case post = "POST"

        var description: String {
            rawValue
        }

        init?(caseInsensitiveString: String?) {
            guard let caseInsensitiveString else { return nil }
            self.init(rawValue: caseInsensitiveString.uppercased())
        }
    }

    enum HeaderKey: String, CustomStringConvertible {
        case accept = "Accept"
        case adType = "x-mediation-ad-type"
        case appID = "x-mediation-app-id"
        case auctionID = "x-mediation-auction-id"
        case contentLength = "Content-Length"
        case contentType = "Content-Type"
        case debug = "x-mediation-debug"
        case deviceOS = "x-mediation-device-os"
        case deviceOSVersion = "x-mediation-device-os-version"
        case idfv = "x-mediation-idfv"
        case loadID = "x-mediation-load-id"
        case queueID = "x-mediation-queue-id"
        case rateLimitReset = "x-mediation-ratelimit-reset"
        case sdkInitHash = "x-mediation-sdk-init-hash"
        case sdkVersion = "x-mediation-sdk-version"
        case sessionID = "x-mediation-session-id"

        var description: String {
            rawValue
        }
    }

    enum HeaderValue {
        static let applicationJSON_chartsetUTF8 = "application/json; charset=utf-8"
    }
}
