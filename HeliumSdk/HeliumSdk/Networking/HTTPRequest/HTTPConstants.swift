// Copyright 2018-2024 Chartboost, Inc.
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
        case auctionID = "X-Mediation-Auction-ID"
        case contentLength = "Content-Length"
        case contentType = "Content-Type"
        case debug = "X-Helium-Debug"
        case deviceOS = "X-Helium-Device-OS"
        case deviceOSVersion = "X-Helium-Device-OS-Version"
        case idfv = "x-mediation-idfv"
        case loadID = "x-mediation-load-id"
        case queueID = "x-mediation-queue-id"
        case rateLimitReset = "x-helium-ratelimit-reset"
        case sdkInitHash = "x-helium-sdk-init-hash"
        case sdkVersion = "X-Helium-SDK-Version"
        case sessionID = "X-Helium-SessionID"

        var description: String {
            rawValue
        }
    }

    enum HeaderValue {
        static let applicationJSON_chartsetUTF8 = "application/json; charset=utf-8"
    }
}
