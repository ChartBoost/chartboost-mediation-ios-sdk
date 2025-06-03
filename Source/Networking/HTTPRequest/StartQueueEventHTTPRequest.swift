// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

struct StartQueueEventHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithDecodableResponse {
    typealias DecodableResponse = [String: String]

    struct Body: Encodable {
        let actualMaxQueueSize: Int
        let appID: String
        let currentQueueDepth: Int
        let placementName: String
        let queueCapacity: Int
        let queueID: String
    }

    let body: Body
    let method = HTTP.Method.post
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase
    let responseKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    let url: URL

    init(
        eventTracker: ServerEventTracker,
        actualMaxQueueSize: Int,
        appID: String,
        currentQueueDepth: Int,
        placementName: String,
        queueCapacity: Int,
        queueID: String
    ) {
        self.url = eventTracker.url
        self.body = Body(
            actualMaxQueueSize: actualMaxQueueSize,
            appID: appID,
            currentQueueDepth: currentQueueDepth,
            placementName: placementName,
            queueCapacity: queueCapacity,
            queueID: queueID
        )
    }
}
