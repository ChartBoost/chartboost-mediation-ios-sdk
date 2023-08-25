// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This protocol represents an HTTP request that has a JSON in the request body.
protocol HTTPRequestWithEncodableBody: HTTPRequest {
    associatedtype Body: Encodable

    var body: Body { get }
    var requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy { get }
}

extension HTTPRequestWithEncodableBody {
    
    var bodyData: Data? {
        get throws {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = requestKeyEncodingStrategy
            return try encoder.encode(body)
        }
    }

    var bodyJSON: [String: Any]? {
        do {
            guard let data = try bodyData else { return nil }
            @Injected(\.jsonSerializer) var serializer
            return try serializer.deserialize(data)
        } catch {
            logger.error("Failed to generate a JSON from body data for [\(self)] with error: \(error)")
            return nil
        }
    }
}
