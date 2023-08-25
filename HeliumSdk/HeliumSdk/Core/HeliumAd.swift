// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A fully loaded Helium ad.
struct HeliumAd {
    /// The bid
    let bid: Bid
    /// Information about the winning bid that may be of interest to the publisher.
    let bidInfo: [String: Any]
    /// The loaded ad obtained from the partner that won the auction.
    let partnerAd: PartnerAd
    /// The request that triggered the load process.
    let request: HeliumAdLoadRequest

    /// Optional Impression level revenue data (ILRD) associated with the bid that won the auction.
    var ilrd: [String: Any]? { bid.ilrd }

    /// Optional rewarded callback data.
    /// This data is used to send a client to server request when the user has earned a reward.
    var rewardedCallback: RewardedCallback? { bid.rewardedCallback }
}
