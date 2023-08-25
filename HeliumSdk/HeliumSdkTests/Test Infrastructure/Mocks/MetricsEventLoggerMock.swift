// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class MetricsEventLoggerMock: Mock<MetricsEventLoggerMock.Method>, MetricsEventLogging {
    
    enum Method {
        case logInitialization
        case logPrebid
        case logLoad
        case logShow
        case logClick
        case logExpiration
        case logHeliumImpression
        case logPartnerImpression
        case logReward
        case logAuctionCompleted
        case logRewardedCallback
    }
    
    override var  defaultReturnValues: [Method : Any?] {
        [.logLoad: nil,
         .logShow: nil]
    }
    
    func logInitialization(_ events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) {
        record(.logInitialization, parameters: [events, result, error])
    }
    
    func logPrebid(loadID: LoadID, events: [MetricsEvent]) {
        record(.logPrebid, parameters: [loadID, events])
    }
    
    func logLoad(auctionID: AuctionID, loadID: LoadID, events: [MetricsEvent], error: ChartboostMediationError?) -> RawMetrics? {
        record(.logLoad, parameters: [auctionID, loadID, events, error])
    }
    
    func logShow(auctionID: AuctionID, loadID: LoadID, event: MetricsEvent) -> RawMetrics? {
        record(.logShow, parameters: [auctionID, loadID, event])
    }
    
    func logClick(auctionID: AuctionID, loadID: LoadID) {
        record(.logClick, parameters: [auctionID, loadID])
    }
    
    func logExpiration(auctionID: AuctionID, loadID: LoadID) {
        record(.logExpiration, parameters: [auctionID, loadID])
    }
    
    func logHeliumImpression(for ad: PartnerAd) {
        record(.logHeliumImpression, parameters: [ad])
    }
    
    func logPartnerImpression(for ad: PartnerAd) {
        record(.logPartnerImpression, parameters: [ad])
    }
    
    func logReward(for ad: PartnerAd) {
        record(.logReward, parameters: [ad])
    }
    
    func logAuctionCompleted(with bids: [Bid], winner: Bid, loadID: LoadID) {
        record(.logAuctionCompleted, parameters: [bids, winner, loadID])
    }
    
    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?) {
        record(.logRewardedCallback, parameters: [rewardedCallback, customData])
    }
}
