// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

struct Bid {
    typealias RewardedCallbackData = OpenRTB.BidResponse.Extension.RewardedCallbackData

    /// A unique identifier for this bid.
    let identifier: String

    /// Partner's identifier.
    let partnerIdentifier: String

    /// Partner's placement identifier.
    let partnerPlacement: String

    /// String containing the bid's adm. Nil for non-programmatic line items.
    let adm: String?

    /// Extra partner-specific information.
    let partnerDetails: [String : Any]?

    /// Helium line item identifier.
    let lineItemIdentifier: String?

    /// Optional Impression level revenue data (ILRD) associated with the bid.
    let ilrd: [String : Any]?

    /// The real or estimated bid price.
    let cpmPrice: Decimal?

    /// The real or estimated revenue of this bid, represented as `cpmPrice / 1000`.
    let adRevenue: Decimal?

    /// Auction identifier common to all bids to the same auction.
    let auctionIdentifier: String

    /// Indicates if the bid is programmatic or not.
    let isProgrammatic: Bool

    /// Data used to send a client to server request when the user has earned a reward.
    let rewardedCallback: RewardedCallback?

    /// Bid price expressed as CPM although the actual transaction is for a unit impression only.
    let clearingPrice: Decimal?

    /// Win notice URL called by the exchange if the bid wins
    let winURL: String?

    /// Loss notice URL called by the exchange when a bid is known to have been lost.
    let lossURL: String?

    /// The size of the ad.
    let size: CGSize?
}

extension Bid {
    @Injected(\.environment) private static var environment

    static func makeBids(response: OpenRTB.BidResponse, request: AdLoadRequest) -> [Bid] {
        guard let seatbids = response.seatbid else {
            return []
        }
        let defaultRewarededCallbackMethod = HTTP.Method.get
        let defaultRewardedCallbackMaxRetries = 2
        let defaultRewardedCallbackRetryDelay: TimeInterval = 1

        var bids: [Bid] = []
        for seatbid in seatbids {
            guard let seat = seatbid.seat else {
                continue
            }
            
            // TODO: Remove this reference adapter hack in HB-4504
            let partnerIdentifier = environment.testMode.isTestModeEnabled && request.heliumPlacement.hasPrefix("REF") ? "reference" : seat

            for rtbBid in seatbid.bid {
                // Merge the bidder's ILRD information with the base ILRD information,
                // giving preference to the bidder's information. In cases where there
                // is no ILRD information, a `nil` value is set.
                let baseILRD = response.ext?.ilrd?.value ?? [:]
                let bidderILRD = rtbBid.ext.ilrd?.value ?? [:]
                let ilrd = bidderILRD.merging(zip(baseILRD.keys, baseILRD.values)) { (current, _) in current }

                // Rewarded callback structure
                var rewardedCallback: RewardedCallback?
                if let rewardedCallbackData = response.ext?.rewarded_callback, let url = rewardedCallbackData.url {
                    rewardedCallback = RewardedCallback(
                        adRevenue: rtbBid.ext.ad_revenue,
                        cpmPrice: rtbBid.ext.cpm_price,
                        partnerIdentifier: partnerIdentifier,
                        urlString: url,
                        method: .init(caseInsensitiveString: rewardedCallbackData.method) ?? defaultRewarededCallbackMethod,
                        maxRetries: rewardedCallbackData.max_retries ?? defaultRewardedCallbackMaxRetries,
                        retryDelay: rewardedCallbackData.retry_delay ?? defaultRewardedCallbackRetryDelay,
                        body: rewardedCallbackData.body
                    )
                }

                var size: CGSize?

                // We've seen odd sizes come back for non-adaptive formats (e.g. 1x1), so we will
                // completely ignore the width and height for non-adaptive formats.
                if request.adFormat == .adaptiveBanner,
                   let width = rtbBid.w,
                   let height = rtbBid.h {
                    size = CGSize(width: width, height: height)
                }

                // The final bid structure
                let bid = Bid(
                    identifier: UUID().uuidString,
                    partnerIdentifier: partnerIdentifier,
                    partnerPlacement: rtbBid.ext.partner_placement ?? "\(seat):\(request.heliumPlacement)",
                    adm: rtbBid.adm,
                    partnerDetails: rtbBid.ext.partnerDetails,
                    lineItemIdentifier: rtbBid.ext.line_item_id,
                    ilrd: ilrd.isEmpty ? nil : ilrd,
                    cpmPrice: rtbBid.ext.cpm_price,
                    adRevenue: rtbBid.ext.ad_revenue,
                    auctionIdentifier: response.id,
                    isProgrammatic: rtbBid.isProgrammatic,
                    rewardedCallback: rewardedCallback,
                    clearingPrice: rtbBid.clearingPrice,
                    winURL: rtbBid.winURL,
                    lossURL: rtbBid.lossURL,
                    size: size
                )
                bids.append(bid)
            }
        }
        return bids
    }
}
