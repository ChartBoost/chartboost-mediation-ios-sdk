// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class AdLoadRequestTests: ChartboostMediationTestCase {

    func testKeywordsMaxLength() throws {
        let maxKeywordKeyLength = 64
        let maxKeywordValueLength = 256

        let key_1 = String(repeating: "1", count: maxKeywordKeyLength)
        let value_1_too_long  = String(repeating: "1", count: maxKeywordValueLength + 1)

        let key_2_too_long  = String(repeating: "2", count: maxKeywordKeyLength + 1)
        let value_2  = String(repeating: "2", count: maxKeywordValueLength)

        let key_3_too_long  = String(repeating: "3", count: maxKeywordKeyLength + 1)
        let value_3_too_long  = String(repeating: "3", count: maxKeywordValueLength + 1)

        let request = AdLoadRequest(
            adSize: nil,
            adFormat: .banner,
            keywords: [
                "key 0": "value 0",
                key_1: value_1_too_long, // the value is too long
                key_2_too_long: value_2, // the key is too long
                key_3_too_long: value_3_too_long, // both key and value are too long
            ],
            mediationPlacement: "",
            loadID: ""
        )
        XCTAssertAnyEqual(request.keywords, [
            "key 0": "value 0",
        ])
    }
}
