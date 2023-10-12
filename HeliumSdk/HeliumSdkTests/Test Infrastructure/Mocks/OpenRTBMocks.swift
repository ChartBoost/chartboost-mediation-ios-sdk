// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

extension OpenRTB.BidResponse {
    static func mock(
        id: String = "mock_id",
        seatbid: [OpenRTB.SeatBid]? = [.mock()],
        ext: OpenRTB.BidResponse.Extension? = .mock()
    ) -> OpenRTB.BidResponse {
        .init(
            id: id,
            seatbid: seatbid,
            ext: ext
        )
    }
}

extension OpenRTB.BidResponse.Extension {
    static func mock(
        ilrd: JSON<[String: Any]>? = nil,
        rewarded_callback: RewardedCallbackData? = .mock()
    ) -> OpenRTB.BidResponse.Extension {
        .init(
            ilrd: ilrd,
            rewarded_callback: rewarded_callback
        )
    }
}

extension OpenRTB.BidResponse.Extension.RewardedCallbackData {
    static func mock(
        url: String? = "https://mock-rewarded-callback-url.com",
        method: String? = "mock_method",
        max_retries: Int? = 1,
        retry_delay: TimeInterval? = 30,
        body: String? = "mock_body"
    ) -> OpenRTB.BidResponse.Extension.RewardedCallbackData {
        .init(
            url: url,
            method: method,
            max_retries: max_retries,
            retry_delay: retry_delay,
            body: body
        )
    }
}

extension OpenRTB.SeatBid {
    static func mock(
        bid: [OpenRTB.Bid] = [.mock()],
        seat: String? = "mock_seat",
        helium_bid_id: String = "mock_helium_bid_id"
    ) -> OpenRTB.SeatBid {
        .init(
            bid: bid,
            seat: seat,
            helium_bid_id: helium_bid_id
        )
    }
}

extension OpenRTB.Bid {
    static func mock(
        id: String = "mock_id",
        price: Decimal? = 42.0,
        nurl: String? = "https://mock-nurl.com",
        lurl: String? = "https://mock-lurl.com",
        adm: String? = "mock_adm",
        ext: OpenRTB.Bid.Extension = .mock(),
        w: Int? = nil,
        h: Int? = nil
    ) -> OpenRTB.Bid {
        .init(
            id: id,
            price: price,
            nurl: nurl,
            lurl: lurl,
            adm: adm,
            ext: ext,
            w: w,
            h: h
        )
    }
}

extension OpenRTB.Bid.Extension {
    static func mock(
        ad_revenue: Decimal? = 42.0,
        line_item_id: String? = "mock_line_item_id",
        cpm_price: Decimal? = 42.0,
        partner_placement: String? = "mock_partner_placement",
        bidder: JSON<[String: Any]>? = nil,
        ilrd: JSON<[String: Any]>? = nil
    ) -> OpenRTB.Bid.Extension {
        .init(
            ad_revenue: ad_revenue,
            line_item_id: line_item_id,
            cpm_price: cpm_price,
            partner_placement: partner_placement,
            bidder: bidder,
            ilrd: ilrd
        )
    }
}
