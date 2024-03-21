// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

struct EndQueueEventHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithDecodableResponse {
    typealias DecodableResponse = [String: String]

    struct Body: Encodable {
        let appID: String
        let currentQueueDepth: Int
        let placementName: String
        let queueCapacity: Int
        let queueID: String
    }

    let body: Body
    let method = HTTP.Method.post
    let responseKeyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase
    var url: URL {
        get throws {
            try makeURL(endpoint: endpoint())
        }
    }

    init(
        appID: String,
        currentQueueDepth: Int,
        placementName: String,
        queueCapacity: Int,
        queueID: String
    ) {
        self.body = Body(
            appID: appID,
            currentQueueDepth: currentQueueDepth,
            placementName: placementName,
            queueCapacity: queueCapacity,
            queueID: queueID
        )
    }

    func endpoint() -> BackendAPI.Endpoint {
        BackendAPI.Endpoint.endQueue
    }
}
