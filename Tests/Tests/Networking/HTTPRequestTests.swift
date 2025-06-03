// Copyright 2018-2025 Chartboost, Inc.
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
                    "x-mediation-session-id": mocks.environment.session.sessionID,
                    "x-mediation-app-id": mocks.environment.app.chartboostAppID,
                    "x-mediation-sdk-version": mocks.environment.sdk.sdkVersion,
                    "x-mediation-device-os": mocks.environment.device.osName,
                    "x-mediation-device-os-version": mocks.environment.device.osVersion,
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
                    "x-mediation-session-id": mocks.environment.session.sessionID,
                    "x-mediation-app-id": mocks.environment.app.chartboostAppID,
                    "x-mediation-sdk-version": mocks.environment.sdk.sdkVersion,
                    "x-mediation-device-os": mocks.environment.device.osName,
                    "x-mediation-device-os-version": mocks.environment.device.osVersion,
                    "key 1": "value 1",
                    "key 2": "value 2"
                ]
            )
            XCTAssertEqual(String(data: try XCTUnwrap(urlRequest.httpBody), encoding: .utf8), bodyDataMock)
        } catch {
            XCTFail("Unexpected failure: obtain `URLRequest` from [\(httpRequest)]")
        }
    }

    func testXHeliumDebugHeader() throws {
        let debugHeaderKey = "x-mediation-debug"
        let appID = "some-app-identifier"
        let httpRequest = try XCTUnwrap(HTTPRequestMock(
            urlString: "http://some.endpoint",
            method: .get,
            customHeaders: ["some key": "some value"],
            bodyData: "some string".data(using: .utf8)
        ))

        // Part 1: nil app ID
        mocks.environment.app.chartboostAppID = nil

        try [false, true, false].forEach { isTestModeEnabled in
            mocks.environment.testMode.isTestModeEnabled = isTestModeEnabled
            let urlRequest = try httpRequest.makeURLRequest()
            XCTAssertFalse(try XCTUnwrap(urlRequest.allHTTPHeaderFields).keys.contains(debugHeaderKey))
        }

        // Part 2: non-nil app ID
        mocks.environment.app.chartboostAppID = appID

        mocks.environment.testMode.isTestModeEnabled = false
        var urlRequest = try httpRequest.makeURLRequest()
        XCTAssertFalse(try XCTUnwrap(urlRequest.allHTTPHeaderFields).keys.contains(debugHeaderKey))

        mocks.environment.testMode.isTestModeEnabled = true
        urlRequest = try httpRequest.makeURLRequest()
        XCTAssertEqual(try XCTUnwrap(urlRequest.allHTTPHeaderFields)[debugHeaderKey], appID)

        mocks.environment.testMode.isTestModeEnabled = false // repeat to test reset
        urlRequest = try httpRequest.makeURLRequest()
        XCTAssertFalse(try XCTUnwrap(urlRequest.allHTTPHeaderFields).keys.contains(debugHeaderKey))
    }
}
