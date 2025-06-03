// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class SDKInitHTTPRequestFactoryTests: ChartboostMediationTestCase {

    lazy var factory = MediationSDKInitHTTPRequestFactory()

    func testMakeRequestWithInitHash() throws {
        var request: SDKInitHTTPRequest?
        factory.makeRequest(sdkInitHash: "some init hash") { result in
            switch result {
            case .success(let httpRequest):
                request = httpRequest
            case .failure:
                XCTFail("Unexpected failure")
            }
        }
        guard let request else {
            XCTFail("Unexpected failure")
            return
        }

        XCTAssertJSONEqual(request.customHeaders, [
            "x-mediation-sdk-init-hash": "some init hash"
        ])
    }

    func testMakeRequestWithNoInitHash() throws {
        var request: SDKInitHTTPRequest?
        factory.makeRequest(sdkInitHash: nil) { result in
            switch result {
            case .success(let httpRequest):
                request = httpRequest
            case .failure:
                XCTFail("Unexpected failure")
            }
        }
        guard let request else {
            XCTFail("Unexpected failure")
            return
        }

        XCTAssertJSONEqual(request.customHeaders, [:])
    }
}
