// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class AppConfigurationServiceTests: ChartboostMediationTestCase {

    private lazy var appConfigService = AppConfigurationService()
    let networkManager = CompleteNetworkManagerMock()
    private let sdkInitHash = "some SDK init hash"
    private let fullSDKInitResponseData = JSONLoader.loadData(.full_sdk_init_response)

    override func setUp() {
        super.setUp()
        mocks.networkManager = networkManager
    }

    /// Backend response 200 (Success) contains SDK init hash and the config data.
    func testFetchSuccessWithHTTPStatusCode200() {
        let sdkInitResponse = NetworkManager.RawDataResponse.test(
            statusCode: 200,
            sdkInitHash: sdkInitHash,
            rawData: fullSDKInitResponseData
        )
        mocks.sdkInitRequestFactory.autoCompletionResult = .success(SDKInitHTTPRequest.test())

        // Fetch app config
        var completed = false
        appConfigService.fetchAppConfiguration(sdkInitHash: nil) { result in // expect non-nil success if 200
            guard case let .success(update) = result, let update else {
                XCTFail("Unexpected result \(result)")
                return
            }

            XCTAssertEqual(update.sdkInitHash, self.sdkInitHash)
            XCTAssertEqual(update.data, self.fullSDKInitResponseData)
            completed = true
        }
        
        // Check SDK init hash is used when creating the HTTP request
        XCTAssertMethodCalls(mocks.sdkInitRequestFactory, .makeRequest, parameters: [
            nil,    // sdkInitHash
            XCTMethodIgnoredParameter()
        ])

        // Finish network manager operation
        var sdkInitRequestCompletion: NetworkManager.RequestCompletionWithRawDataResponse = { _ in }
        XCTAssertMethodCalls(networkManager, .send, parameters: [XCTMethodIgnoredParameter(), 0, 0.0, XCTMethodCaptureParameter { sdkInitRequestCompletion = $0 }])
        sdkInitRequestCompletion(.success(sdkInitResponse))

        XCTAssertTrue(completed)
    }

    /// Backend response 204 (No Content) does not contain the config data because it should have
    /// been stored locally after previous 200 (Success) response.
    func testFetchSuccessWithHTTPStatusCode204() {
        let sdkInitResponse = NetworkManager.RawDataResponse.test(
            statusCode: 204,
            sdkInitHash: sdkInitHash,
            rawData: fullSDKInitResponseData
        )
        mocks.sdkInitRequestFactory.autoCompletionResult = .success(SDKInitHTTPRequest.test())

        // Fetch app config
        var completed = false
        appConfigService.fetchAppConfiguration(sdkInitHash: sdkInitHash) { result in
            guard case let .success(update) = result, update == nil else {  // expect nil success if 204
                XCTFail("Unexpected result \(result)")
                return
            }
            completed = true
        }

        // Check SDK init hash is used when creating the HTTP request
        XCTAssertMethodCalls(mocks.sdkInitRequestFactory, .makeRequest, parameters: [
            sdkInitHash,
            XCTMethodIgnoredParameter()
        ])

        // Finish network manager operation
        var sdkInitRequestCompletion: NetworkManager.RequestCompletionWithRawDataResponse = { _ in }
        XCTAssertMethodCalls(networkManager, .send, parameters: [XCTMethodIgnoredParameter(), 0, 0.0, XCTMethodCaptureParameter { sdkInitRequestCompletion = $0 }])
        sdkInitRequestCompletion(.success(sdkInitResponse))

        XCTAssertTrue(completed)
    }

    func testFetchFailureWithErrorStatusCode() {
        let sdkInitError = NetworkManager.RequestError.responseStatusCodeOutOfRangeError(
            httpRequest: SDKInitHTTPRequest.test(),
            httpURLResponse: .init(),
            maxRetries: 0
        )
        mocks.sdkInitRequestFactory.autoCompletionResult = .success(SDKInitHTTPRequest.test())

        // Fetch app config
        var completed = false
        appConfigService.fetchAppConfiguration(sdkInitHash: sdkInitHash) { result in
            guard case let .failure(error) = result else {
                XCTFail("Unexpected result \(result)")
                return
            }
            XCTAssertEqual(error.domain, "com.chartboost.mediation")
            XCTAssertEqual(error.code, ChartboostMediationError.Code.initializationFailureServerError.rawValue)
            completed = true
        }

        // Finish network manager operation
        var sdkInitRequestCompletion: NetworkManager.RequestCompletionWithRawDataResponse = { _ in }
        XCTAssertMethodCalls(networkManager, .send, parameters: [XCTMethodIgnoredParameter(), 0, 0.0, XCTMethodCaptureParameter { sdkInitRequestCompletion = $0 }])
        sdkInitRequestCompletion(.failure(sdkInitError))

        XCTAssertTrue(completed)
    }
}
