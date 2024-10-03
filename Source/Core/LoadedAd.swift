// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A fully loaded ad.
struct LoadedAd {
    /// ID for the auction associated to this ad.
    var auctionID: String { winner.auctionID }

    /// All bids
    let bids: [Bid]

    /// The winning bid
    let winner: Bid

    /// The winning bid price.
    var price: Decimal { winner.clearingPrice ?? -1 }

    /// The type of load.
    var type: String { winner.isProgrammatic ? "bidding" : "mediation" }

    /// Information about the winning bid that may be of interest to the publisher.
    let bidInfo: [String: Any]

    /// The loaded ad obtained from the partner that won the auction.
    let partnerAd: PartnerAd

    /// The partner banner view, or `nil` for fullscreen ads.
    var bannerView: UIView? {
        (partnerAd as? PartnerBannerAd)?.view
    }

    /// The size of the loaded banner, or `nil` for old adapter versions and fullscreen ads.
    let bannerSize: BannerSize?

    /// The request that triggered the load process.
    let request: InternalAdLoadRequest

    /// Optional Impression level revenue data (ILRD) associated with the bid that won the auction.
    var ilrd: [String: Any]? { winner.ilrd }

    /// Optional rewarded callback data.
    /// This data is used to send a client to server request when the user has earned a reward.
    var rewardedCallback: RewardedCallback? { winner.rewardedCallback }
}

extension LoadedAd {
    struct Bidder: Encodable {
        let lurl: String?
        let nurl: String?
        let price: Decimal
        let seat: String

        init(bid: Bid) {
            lurl = bid.isProgrammatic ? bid.lossURL : nil
            nurl = bid.isProgrammatic ? bid.winURL : nil
            price = bid.clearingPrice ?? 0
            seat = bid.partnerID
        }
    }

    // Bids mapped to a Bidder, for impression tracking events.
    var bidders: [Bidder] { bids.map { Bidder(bid: $0) } }
}
