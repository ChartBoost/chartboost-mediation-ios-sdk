// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class AppConfigurationServiceTests: HeliumTestCase {

    private lazy var appConfigService = AppConfigurationService()
    private static let sdkInitHash = "some SDK init hash"
    private static let testExpectationDescription = "test SDK init"
    private static let fullSDKInitResponseData = JSONLoader.loadData(.full_sdk_init_response)

    @Injected(\.environment) private var environment
    private var sdkInitURLString: String { "https://helium-sdk.chartboost.com/v1/sdk_init/\(environment.app.appID!)" }
    private var sdkInitURL: URL { URL(string: sdkInitURLString)! }

    /// Backend response 200 (Success) contains SDK init hash and the config data.
    func testFetchSuccessWithHTTPStatusCode200() {
        let statusCode = 200
        URLProtocolMock.registerRequestHandler(httpMethod: "GET", urlString: sdkInitURLString) { [unowned self] request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [
                "Accept": "application/json; charset=utf-8",
                "Content-Type": "application/json; charset=utf-8",
                "X-Helium-SessionID": environment.session.sessionID.uuidString,
                "X-Helium-Device-OS": environment.device.osName,
                "X-Helium-Device-OS-Version": environment.device.osVersion,
                "X-Helium-SDK-Version": environment.sdk.sdkVersion
            ])

            return (
                response: HTTPURLResponse(
                    url: self.sdkInitURL,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: ["x-helium-sdk-init-hash": Self.sdkInitHash]
                ),
                data: Self.fullSDKInitResponseData
            )
        }

        let expectation = XCTestExpectation(description: Self.testExpectationDescription)
        appConfigService.fetchAppConfiguration(sdkInitHash: nil) { result in // expect non-nil success if 200
            guard case let .success(update) = result, let update else {
                XCTFail("Unexpected result \(result)")
                return
            }

            XCTAssertEqual(update.sdkInitHash, Self.sdkInitHash)
            XCTAssertFalse(update.data.isEmpty)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    /// Backend response 204 (No Content) does not contain the config data because it should have
    /// been stored locally after previous 200 (Success) response.
    func testFetchSuccessWithHTTPStatusCode204() {
        let statusCode = 204
        URLProtocolMock.registerRequestHandler(httpMethod: "GET", urlString: sdkInitURLString) { [unowned self] request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [
                "Accept": "application/json; charset=utf-8",
                "Content-Type": "application/json; charset=utf-8",
                "X-Helium-SessionID": environment.session.sessionID.uuidString,
                "X-Helium-Device-OS": environment.device.osName,
                "X-Helium-Device-OS-Version": environment.device.osVersion,
                "X-Helium-SDK-Version": environment.sdk.sdkVersion,
                "x-helium-sdk-init-hash": Self.sdkInitHash
            ])

            return (
                response: HTTPURLResponse(
                    url: self.sdkInitURL,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: ["x-helium-sdk-init-hash": Self.sdkInitHash]
                ),
                data: Data()
            )
        }

        let expectation = XCTestExpectation(description: Self.testExpectationDescription)
        appConfigService.fetchAppConfiguration(sdkInitHash: Self.sdkInitHash) { result in
            guard case let .success(update) = result, update == nil else {  // expect nil success if 204
                XCTFail("Unexpected result \(result)")
                return
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }

    func testFetchFailureWithErrorStatusCode() {
        let statusCode = 500
        URLProtocolMock.registerRequestHandler(httpMethod: "GET", urlString: sdkInitURLString) { [unowned self] request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.allHTTPHeaderFields, [
                "Accept": "application/json; charset=utf-8",
                "Content-Type": "application/json; charset=utf-8",
                "X-Helium-SessionID": environment.session.sessionID.uuidString,
                "X-Helium-Device-OS": environment.device.osName,
                "X-Helium-Device-OS-Version": environment.device.osVersion,
                "X-Helium-SDK-Version": environment.sdk.sdkVersion,
                "x-helium-sdk-init-hash": Self.sdkInitHash
            ])

            return (
                response: HTTPURLResponse(
                    url: self.sdkInitURL,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                ),
                data: Data()
            )
        }

        let expectation = XCTestExpectation(description: Self.testExpectationDescription)
        appConfigService.fetchAppConfiguration(sdkInitHash: Self.sdkInitHash) { result in
            guard case let .failure(error) = result else {
                XCTFail("Unexpected result \(result)")
                return
            }
            XCTAssertEqual(error.domain, "com.chartboost.mediation")
            XCTAssertEqual(error.code, ChartboostMediationError.Code.initializationFailureServerError.rawValue)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1)
    }
}
