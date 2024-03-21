// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A fully loaded ad.
struct LoadedAd {
    /// Key for auction identifier in bidInfo dictionary
    static let auctionIDKey = "auction-id"
    /// Key for partner's identifier in bidInfo dictionary
    static let partnerIDKey = "partner-id"
    /// Key for bid price in bidInfo dictionary
    static let priceKey = "price"
    /// Key for line item ID in bidInfo dictionary
    static let lineItemIDKey = "line_item_id"
    /// Key for line item name in bidInfo dictionary
    static let lineItemNameKey = "line_item_name"

    /// The bid
    let bid: Bid
    /// Information about the winning bid that may be of interest to the publisher.
    let bidInfo: [String: Any]
    /// The loaded ad obtained from the partner that won the auction.
    let partnerAd: PartnerAd
    /// The size of the loaded banner, or `nil` for old adapter versions and fullscreen ads.
    let adSize: ChartboostMediationBannerSize?
    /// The request that triggered the load process.
    let request: AdLoadRequest

    /// Optional Impression level revenue data (ILRD) associated with the bid that won the auction.
    var ilrd: [String: Any]? { bid.ilrd }

    /// Optional rewarded callback data.
    /// This data is used to send a client to server request when the user has earned a reward.
    var rewardedCallback: RewardedCallback? { bid.rewardedCallback }
}
