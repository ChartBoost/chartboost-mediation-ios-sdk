// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension Bid {
    static let defaultPartnerIdentifierMock = "some partnerIdentifier"

    static func makeMock(
        adRevenue: Double? = 4.2,
        cpmPrice: Double? = 2.4,
        partnerIdentifier: PartnerIdentifier = defaultPartnerIdentifierMock,
        rewardedCallbackData: RewardedCallbackData? = nil,
        lineItemName: String? = nil
    ) -> Bid {
        var rewardedCallback: RewardedCallback?
        if let rewardedCallbackData = rewardedCallbackData, let url = rewardedCallbackData.url {
            rewardedCallback = RewardedCallback(
                adRevenue: adRevenue,
                cpmPrice: cpmPrice,
                partnerIdentifier: partnerIdentifier,
                urlString: url,
                method: .init(caseInsensitiveString: rewardedCallbackData.method) ?? .get,
                maxRetries: rewardedCallbackData.max_retries ?? 2,
                retryDelay: rewardedCallbackData.retry_delay ?? 1,
                body: rewardedCallbackData.body
            )
        }
        var ilrd: [String: Any] = ["a": 1, "2": "b", "92jfo92": [1, 2, 3]]
        if let lineItemName {
            ilrd["line_item_name"] = lineItemName
        }
        return Bid(
            identifier: "some identifier \(Int.random(in: 1...99999))",
            partnerIdentifier: "some partnerIdentifier",
            partnerPlacement: "some partnerPlacement",
            adm: "some adm \(Int.random(in: 1...99999))",
            partnerDetails: ["a": "1", "2": "b", "92jfo92": "_asfd!#d"],
            lineItemIdentifier: "some lineItemIdentifier",
            ilrd: ilrd,
            cpmPrice: cpmPrice,
            adRevenue: adRevenue,
            auctionIdentifier: "some auctionIdentifier",
            isProgrammatic: true,
            rewardedCallback: rewardedCallback,
            clearingPrice: 42.24,
            winURL: "winURL",
            lossURL: "lossURL"
        )
    }
}
