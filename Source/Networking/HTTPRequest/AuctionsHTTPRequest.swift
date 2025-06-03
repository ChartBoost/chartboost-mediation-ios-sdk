// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import AppTrackingTransparency
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

    @Injected(\.environment) private var environment

    var url: URL {
        get throws {
            // iOS 17 introduces Privacy Manifests with Tracking Domains, thus we need to split the
            // /auction endpoint into a tracking version and a non-tracking version.
            if #available(iOS 17, *) {
                switch environment.appTracking.trackingAuthorizationStatus {
                case .authorized:
                    // Requests sent to this endpoint might contain privacy tracking data such as IDFA.
                    // The privacy tracking data might be erased due to non-Apple compliance requirements
                    // such as GDPR and COPPA.
                    return try makeURL(endpoint: .auction_tracking)

                case .notDetermined, .restricted, .denied:
                    // Requests sent to this endpoint must not contain any privacy tracking data.
                    return try makeURL(endpoint: .auction_nonTracking)

                @unknown default:
                    // Same as the not-authorized case.
                    assertionFailure("Unknown `appTransparencyAuthStatus`: \(environment.appTracking.trackingAuthorizationStatus)")
                    return try makeURL(endpoint: .auction_nonTracking)
                }
            } else {
                // Use the tracking version of the auction endpoint because only iOS 17+ might block
                // it as a Tracking Domain reported in the Privacy Manifest.
                return try makeURL(endpoint: .auction_tracking)
            }
        }
    }

    init(adFormat: AdFormat, bidRequest: OpenRTB.BidRequest, loadRateLimit: Int, loadID: LoadID, queueID: String? = nil) {
        customHeaders = [
            HTTP.HeaderKey.adType.rawValue: adFormat.rawValue,
            HTTP.HeaderKey.loadID.rawValue: loadID,
            HTTP.HeaderKey.rateLimitReset.rawValue: "\(loadRateLimit)",
            HTTP.HeaderKey.queueID.rawValue: queueID,
        ].compactMapValues { $0 }  // Filter out queueID when it's nil
        body = bidRequest
    }
}
