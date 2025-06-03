// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// This `WinnerEventHTTPRequest` is only for `/event/winner` but not other `/event` because the
/// POST payload of `/event/winner` is very different from the other `/event` tracking events,
/// with only `"auction_id"` in common.
struct WinnerEventHTTPRequest: HTTPRequestWithEncodableBody, HTTPRequestWithRawDataResponse {
    struct Body: Encodable {
        let auctionID: String
        let bidders: [Bidder]
        let lineItemID: String?
        let partnerPlacement: String?
        let price: Decimal
        let type: String
        let winner: String
        let placementType: AdFormat
        let size: BackendEncodableSize?

        init(winner: Bid, of bids: [Bid], adFormat: AdFormat, size: CGSize?) {
            auctionID = winner.auctionID
            bidders = bids.map { Bidder(bid: $0) }
            lineItemID = winner.lineItemIdentifier
            partnerPlacement = winner.isProgrammatic ? nil : winner.partnerPlacement
            price = winner.clearingPrice ?? -1
            type = winner.isProgrammatic ? "bidding" : "mediation"
            self.winner = winner.partnerID

            placementType = adFormat

            // Size can be omitted if the format is not `adaptiveBanner`.
            if adFormat == .adaptiveBanner {
                // If size is nil for some reason, we need to send 0s, or else the server will
                // return a 400 error.
                self.size = size?.backendEncodableSize ?? CGSize.zero.backendEncodableSize
            } else {
                self.size = nil
            }
        }

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
    }

    let method = HTTP.Method.post
    let customHeaders: HTTP.Headers
    let body: Body
    let requestKeyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .convertToSnakeCase

    let url: URL

    init(eventTracker: ServerEventTracker, winner: Bid, of bids: [Bid], loadID: LoadID, adFormat: AdFormat, size: CGSize?) {
        self.url = eventTracker.url
        body = .init(winner: winner, of: bids, adFormat: adFormat, size: size)
        customHeaders = [
            HTTP.HeaderKey.adType.rawValue: adFormat.rawValue,
            HTTP.HeaderKey.loadID.rawValue: loadID,
        ]
    }
}
