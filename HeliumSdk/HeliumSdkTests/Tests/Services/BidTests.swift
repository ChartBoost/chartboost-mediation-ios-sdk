// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

final class BidTests: HeliumTestCase {

    /// Validate that no rewarded callback object is created when there is no data specified.
    func testNoData() throws {
        let bid = Bid.makeMock(rewardedCallbackData: nil)
        XCTAssertNil(bid.rewardedCallback)
    }

    /// Validate that no rewarded callback object is created when there is no URL specified.
    func testNoURL() throws {
        let dictionary: [String: Any] = [
            "method": "POST",
            "max_retries": 5,
            "body": "{\"load_ts\":123232445434,\"hash\":\"999123424212324122324\",\"data\":\"%%CUSTOM_DATA%%\",\"imp_ts\":\"%%SDK_TIMESTAMP%%\",\"keyword_A\":\"value_of_keyword_A_set_by_server\",\"hello\":\"world\",\"network\":\"%%NETWORK_NAME%%\",\"revenue\":%%AD_REVENUE%%}"
        ]
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        let decoder = JSONDecoder()
        let rewardedCallbackData = try decoder.decode(RewardedCallbackData.self, from: data)
        let bid = Bid.makeMock(rewardedCallbackData: rewardedCallbackData)
        XCTAssertNil(bid.rewardedCallback)
    }
}
