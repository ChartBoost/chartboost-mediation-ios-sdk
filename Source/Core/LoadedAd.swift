// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A fully loaded ad.
struct LoadedAd {
    /// ID for the auction associated to this ad.
    var auctionID: String { bid.auctionID }

    /// The bid
    let bid: Bid

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
    var ilrd: [String: Any]? { bid.ilrd }

    /// Optional rewarded callback data.
    /// This data is used to send a client to server request when the user has earned a reward.
    var rewardedCallback: RewardedCallback? { bid.rewardedCallback }
}
