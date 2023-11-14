// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// OpenRTB 2.5 spec: https://www.iab.com/wp-content/uploads/2016/03/OpenRTB-API-Specification-Version-2-5-FINAL.pdf

import Foundation

typealias RewardedCallbackData = OpenRTB.BidResponse.Extension.RewardedCallbackData

extension OpenRTB {
    struct BidResponse: Decodable {
        /// ID of the bid request to which this is a response.
        let id: String

        /// Array of `SeatBid` objects; 1+ required if a bid is to be made.
        let seatbid: [SeatBid]?

        /// Extension (implementation-specific) data
        let ext: Extension?

        struct Extension: Decodable {
            // Impression level revenue data
            let ilrd: JSON<[String: Any]>?

            // Data needed for performing a callback to a backend when a reward has been given
            let rewarded_callback: RewardedCallbackData?

            struct RewardedCallbackData: Decodable {
                var url: String?
                var method: String?
                var max_retries: Int?
                var retry_delay: TimeInterval?
                var body: String?
            }
        }
    }

    struct SeatBid: Decodable {
        /// Array of 1+ `Bid` objects each related to an impression. Multiple bids can relate to the same impression.
        let bid: [Bid]

        /// ID of the buyer seat (e.g., advertiser, agency) on whose behalf this bid is made.
        let seat: String?

        /// Custom `helium_bid_id`
        let helium_bid_id: String
    }

    // The ChartboostMediationSDK does not use `impid`, so it is not included.
    // The OpenRTB spec defines price as non-optional, but the ChartboostMediationSDK assumes that it is optional.
    struct Bid: Decodable {
        /// Bidder generated bid ID to assist with logging/tracking.
        let id: String

        /// Bid price expressed as CPM although the actual transaction is for a unit impression only.
        let price: Decimal?

        /// Win notice URL called by the exchange if the bid wins (not necessarily indicative of a delivered, viewed, or billable ad);
        /// optional means of serving ad markup. Substitution macros (Section 4.4) may be included in both the URL and optionally returned markup.
        let nurl: String?

        /// Loss notice URL called by the exchange when a bid is known to have been lost. Substitution macros (Section 4.4) may be
        /// included. Exchange-specific policy may preclude support for loss notices or the disclosure of winning clearing prices
        /// resulting in ${AUCTION_PRICE} macros being removed (i.e., replaced with a zero-length string).
        let lurl: String?

        /// Optional means of conveying ad markup in case the bid wins; supersedes the win notice if markup is included in both.
        /// Substitution macros (Section 4.4) may be included.
        let adm: String?

        /// Extention (implementation-specific) data
        let ext: Extension

        /// Width of the creative in device independent pixels.
        let w: Int?

        /// Height of the creative in device independent pixels.
        let h: Int?

        struct Extension: Decodable {
            let ad_revenue: Decimal?
            let line_item_id: String?
            let cpm_price: Decimal?
            let partner_placement: String?
            let bidder: JSON<[String: Any]>?

            // Impression level revenue data
            let ilrd: JSON<[String: Any]>?
        }
    }
}

// MARK: - Aliases

extension OpenRTB.Bid.Extension {
    private static let bidderHeliumKey = "helium"

    var partnerDetails: [String: Any]? {
        bidder?.value[Self.bidderHeliumKey] as? [String: Any]
    }
}
