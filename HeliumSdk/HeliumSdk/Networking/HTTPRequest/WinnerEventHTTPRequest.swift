// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This `WinnerEventHTTPRequest` is only for `/event/winner` but not other `/event` because the
/// POST payload of `/event/winner` is very different from the other `/event` tracking events,
/// with only `"auction_id"` in common.
/// Spec: go/cm-tracking-events
struct WinnerEventHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithRawDataResponse {

    struct Body: Encodable {
        let auctionID: String
        let bidders: [Bidder]
        let lineItemID: String?
        let partnerPlacement: String?
        let price: Double
        let type: String
        let winner: String

        init(winner: Bid, of bids: [Bid]) {
            auctionID = winner.auctionIdentifier
            bidders = bids.map { Bidder(bid: $0) }
            lineItemID = winner.lineItemIdentifier
            partnerPlacement = winner.isProgrammatic ? nil : winner.partnerPlacement
            price = winner.clearingPrice ?? -1
            type = winner.isProgrammatic ? "bidding" : "mediation"
            self.winner = winner.partnerIdentifier
        }

        struct Bidder: Encodable {
            let lurl: String?
            let nurl: String?
            let price: Double
            let seat: String

            init(bid: Bid) {
                lurl = bid.isProgrammatic ? bid.lossURL : nil
                nurl = bid.isProgrammatic ? bid.winURL : nil
                price = bid.clearingPrice ?? 0
                seat = bid.partnerIdentifier
            }
        }
    }

    let method = HTTP.Method.post
    let customHeaders: HTTP.Headers
    let body: Body
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase

    var url: URL {
        get throws {
            try makeURL(backendAPI: .sdk, path: BackendAPI.Path.SDK.Event.winner)
        }
    }

    init(winner: Bid, of bids: [Bid], loadID: LoadID) {
        body = .init(winner: winner, of: bids)
        customHeaders = [HTTP.HeaderKey.loadID.rawValue: loadID]
    }
}
