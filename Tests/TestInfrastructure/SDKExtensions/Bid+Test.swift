// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension Bid {
    static let defaultPartnerIDMock = "some partnerIdentifier"

    static func test(
        identifier: String = "some identifier \(Int.random(in: 1...99999))",
        partnerID: String = defaultPartnerIDMock,
        partnerPlacement: String = "some partnerPlacement",
        adm: String = "some adm \(Int.random(in: 1...99999))",
        partnerDetails: [String: Any]? = ["BidMock-value-a": "9krvuN", "BidMock-value-b": "YYL7ix", "BidMock-value-c": "MJRquP"],
        lineItemIdentifier: String = "some lineItemIdentifier",
        adRevenue: Decimal? = Decimal(string: "4.2"),
        cpmPrice: Decimal? = Decimal(string: "2.4"),
        auctionID: String = "some auctionIdentifier",
        isProgrammatic: Bool = true,
        clearingPrice: Decimal? = Decimal(string: "42.24"),
        winURL: String? = "winURL",
        lossURL: String? = "lossURL",
        size: CGSize? = nil,
        // The following two aren't part of the Bid object directly, but are used as for
        // compatibility with old tests that used them as a convenience.
        rewardedCallbackData: RewardedCallbackData? = nil,
        lineItemName: String? = nil
    ) -> Bid {
        var rewardedCallback: RewardedCallback?
        if let rewardedCallbackData = rewardedCallbackData, let url = rewardedCallbackData.url {
            rewardedCallback = RewardedCallback(
                adRevenue: adRevenue,
                cpmPrice: cpmPrice,
                partnerID: partnerID,
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
            identifier: identifier,
            partnerID: partnerID,
            partnerPlacement: partnerPlacement,
            adm: adm,
            partnerDetails: partnerDetails,
            lineItemIdentifier: lineItemIdentifier,
            ilrd: ilrd,
            cpmPrice: cpmPrice,
            adRevenue: adRevenue,
            auctionID: auctionID,
            isProgrammatic: isProgrammatic,
            rewardedCallback: rewardedCallback,
            clearingPrice: clearingPrice,
            winURL: winURL,
            lossURL: lossURL,
            size: size
        )
    }
}
