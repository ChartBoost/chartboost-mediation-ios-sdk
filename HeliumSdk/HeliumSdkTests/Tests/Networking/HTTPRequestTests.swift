// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class HTTPRequestTests: ChartboostMediationTestCase {

    func testCreateURLRequestWithComponents() throws {
        let endpoint = BackendAPI.Endpoint.auction_nonTracking
        let method = HTTP.Method.get
        let path = "/path"
        let headers: HTTP.Headers = [
            "key 1": "value 1",
            "key 2": "value 2"
        ]
        let bodyDataMock = "some string"
        let httpRequest = HTTPRequestMock(
            endpoint: endpoint,
            urlPath: path,
            method: method,
            customHeaders: headers,
            bodyData: bodyDataMock.data(using: .utf8)
        )

        do {
            let urlRequest = try httpRequest.makeURLRequest()
            XCTAssertEqual(urlRequest.httpMethod, method.rawValue)
            XCTAssertEqual(urlRequest.url?.absoluteString, "\(endpoint.scheme)://\(endpoint.host)\(path)")
            XCTAssertAnyEqual(
                try XCTUnwrap(urlRequest.allHTTPHeaderFields),
                [
                    "Accept": "application/json; charset=utf-8",
                    "Content-Type": "application/json; charset=utf-8",
                    "X-Helium-SessionID": mocks.environment.session.sessionID.uuidString,
                    "key 1": "value 1",
                    "key 2": "value 2"
                ]
            )
            XCTAssertEqual(String(data: try XCTUnwrap(urlRequest.httpBody), encoding: .utf8), bodyDataMock)
        } catch {
            XCTFail("Unexpected failure: obtain `URLRequest` from [\(httpRequest)]")
        }
    }

    func testCreateURLRequestWithURLString() throws {
        let endpoint = BackendAPI.Endpoint.auction_nonTracking
        let path = "/path"
        let urlString = "\(endpoint.scheme)://\(endpoint.host)\(path)"
        let method = HTTP.Method.get
        let headers: HTTP.Headers = [
            "key 1": "value 1",
            "key 2": "value 2"
        ]
        let bodyDataMock = "some string"
        let httpRequest = try XCTUnwrap(HTTPRequestMock(
            urlString: urlString,
            method: method,
            customHeaders: headers,
            bodyData: bodyDataMock.data(using: .utf8)
        ))

        do {
            let urlRequest = try httpRequest.makeURLRequest()
            XCTAssertEqual(urlRequest.httpMethod, method.rawValue)
            XCTAssertEqual(urlRequest.url?.absoluteString, urlString)
            XCTAssertAnyEqual(
                try XCTUnwrap(urlRequest.allHTTPHeaderFields),
                [
                    "Accept": "application/json; charset=utf-8",
                    "Content-Type": "application/json; charset=utf-8",
                    "X-Helium-SessionID": mocks.environment.session.sessionID.uuidString, 
                    "key 1": "value 1",
                    "key 2": "value 2"
                ]
            )
            XCTAssertEqual(String(data: try XCTUnwrap(urlRequest.httpBody), encoding: .utf8), bodyDataMock)
        } catch {
            XCTFail("Unexpected failure: obtain `URLRequest` from [\(httpRequest)]")
        }
    }
}
