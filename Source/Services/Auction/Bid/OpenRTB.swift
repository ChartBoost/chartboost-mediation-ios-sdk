// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

// OpenRTB 2.5 spec: https://www.iab.com/wp-content/uploads/2016/03/OpenRTB-API-Specification-Version-2-5-FINAL.pdf

import Foundation

enum OpenRTB {}

extension OpenRTB {
    /// The following enumeration specifies the position of the ad as a relative measure of visibility or prominence.
    /// This OpenRTB enumeration has values derived from the Inventory Quality Guidelines (IQG). Practitioners should
    /// keep in sync with updates to the IQG values as published on IAB.com. Values “4” - “7” apply to apps per the mobile
    /// addendum to IQG version 2.1.
    /// - Note: Conforms to OpenRTB 2.5 specification 5.4
    enum AdPosition: Int, Codable {
        case unknown = 0
        case aboveTheFold = 1
        case belowTheFold = 3
        case header = 4
        case footer = 5
        case sidebar = 6
        case fullScreen = 7

        // MARK: Deprecated AdPosition values

        /// DEPRECATED
        case mayNotBeInitiallayVisible = 2
    }
}

// Aliases

extension OpenRTB.Bid {
    /// Bidder generated bid ID to assist with logging/tracking.
    var auctionID: String { id }
    /// Bid price expressed as CPM although the actual transaction is for a unit impression only.
    var clearingPrice: Decimal? { price }
    /// Indicates if the bid is programmatic or not.
    var isProgrammatic: Bool { id != "MEDIATION" }
    /// Win notice URL called by the exchange if the bid wins
    var winURL: String? { nurl }
    /// Loss notice URL called by the exchange when a bid is known to have been lost.
    var lossURL: String? { lurl }
}
