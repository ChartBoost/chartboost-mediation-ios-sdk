// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class FullscreenLoadAdRequestTests: ChartboostMediationTestCase {

    func testInitWithoutKeywords() {
        let request = FullscreenAdLoadRequest(placement: "hello")

        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, [String: String]())
    }

    func testInitWithKeywords() {
        let request = FullscreenAdLoadRequest(placement: "hello", keywords: ["asdf": "1234"])

        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, ["asdf": "1234"])
    }

    func testInitWithQueueID() {
        let request = FullscreenAdLoadRequest(placement: "hello", keywords: ["asdf": "1234"], partnerSettings: nil, queueID: "9876")

        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, ["asdf": "1234"])
        XCTAssertEqual(request.queueID, "9876")
    }

    func testInitWithKeywordsAndPartnerSettings() {
        let request = FullscreenAdLoadRequest(placement: "hello", keywords: ["asdf": "1234"], partnerSettings: ["jkl;" : "5678"])

        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, ["asdf": "1234"])
        XCTAssertAnyEqual(request.partnerSettings, ["jkl;" : "5678"])
    }

    func testInitWithKeywordsPartnerSettingsAndQueueID() {
        let request = FullscreenAdLoadRequest(
            placement: "hello",
            keywords: ["asdf": "1234"],
            partnerSettings: ["jkl;" : "5678"],
            queueID: "qwert"
        )

        XCTAssertEqual(request.placement, "hello")
        XCTAssertAnyEqual(request.keywords, ["asdf": "1234"])
        XCTAssertAnyEqual(request.partnerSettings, ["jkl;" : "5678"])
        XCTAssertEqual(request.queueID, "qwert")
    }
}
