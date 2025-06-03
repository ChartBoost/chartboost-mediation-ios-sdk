// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class BackendEncodableSizeTests: ChartboostMediationTestCase {
    func testInitFromCGSize() {
        let size = BackendEncodableSize(cgSize: CGSize(width: 100, height: 100))
        XCTAssertEqual(size.width, 100)
        XCTAssertEqual(size.height, 100)
    }

    func testInitFromCGSizeCeil() {
        let size = BackendEncodableSize(cgSize: CGSize(width: 100.1, height: 100.9))
        XCTAssertEqual(size.width, 101)
        XCTAssertEqual(size.height, 101)
    }

    func testBackendEncodableSizeEncode() throws {
        let expectedResult: [String: Any] = [
            "w": 100,
            "h": 100
        ]
        let size = BackendEncodableSize(cgSize: CGSize(width: 100, height: 100))
        let data = try JSONEncoder().encode(size)
        let jsonDict = try JSONSerialization.jsonDictionary(with: data)
        XCTAssertAnyEqual(jsonDict, expectedResult)
    }
}
