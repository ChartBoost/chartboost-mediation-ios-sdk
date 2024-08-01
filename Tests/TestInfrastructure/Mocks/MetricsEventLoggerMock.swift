// Copyright 2018-2024 Chartboost, Inc.
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
        case logStartQueue
        case logEndQueue
    }
    
    override var  defaultReturnValues: [Method : Any?] {
        [.logLoad: nil,
         .logShow: nil]
    }
    
    func logInitialization(_ events: [MetricsEvent], result: SDKInitResult, error: ChartboostMediationError?) {
        record(.logInitialization, parameters: [events, result, error])
    }
    
    func logPrebid(for request: PartnerAdPreBidRequest, events: [MetricsEvent]) {
        record(.logPrebid, parameters: [request, events])
    }
    
    func logLoad(auctionID: ChartboostMediationSDK.AuctionID, loadID: ChartboostMediationSDK.LoadID, events: [ChartboostMediationSDK.MetricsEvent], error: ChartboostMediationSDK.ChartboostMediationError?, adFormat: ChartboostMediationSDK.AdFormat, size: CGSize?, start: Date, end: Date, backgroundDuration: TimeInterval, queueID: String?) -> ChartboostMediationSDK.RawMetrics? {
        record(.logLoad, parameters: [auctionID, loadID, events, error, adFormat, size, start, end, backgroundDuration])
    }
    
    func logShow(for ad: LoadedAd, start: Date, error: ChartboostMediationError?) -> RawMetrics? {
        record(.logShow, parameters: [ad, start, error])
    }
    
    func logClick(for ad: PartnerAd) {
        record(.logClick, parameters: [ad])
    }
    
    func logExpiration(for ad: PartnerAd) {
        record(.logExpiration, parameters: [ad])
    }
    
    func logMediationImpression(for ad: LoadedAd) {
        record(.logHeliumImpression, parameters: [ad])
    }
    
    func logPartnerImpression(for ad: PartnerAd) {
        record(.logPartnerImpression, parameters: [ad])
    }
    
    func logReward(for ad: PartnerAd) {
        record(.logReward, parameters: [ad])
    }

    func logAuctionCompleted(with bids: [ChartboostMediationSDK.Bid], winner: ChartboostMediationSDK.Bid, loadID: ChartboostMediationSDK.LoadID, adFormat: ChartboostMediationSDK.AdFormat, size: CGSize?) {
        record(.logAuctionCompleted, parameters: [bids, winner, loadID, adFormat, size])
    }
    
    func logRewardedCallback(_ rewardedCallback: RewardedCallback, customData: String?) {
        record(.logRewardedCallback, parameters: [rewardedCallback, customData])
    }

    func logStartQueue(_ queue: ChartboostMediationSDK.FullscreenAdQueue) {
        record(.logStartQueue)
    }

    func logEndQueue(_ queue: ChartboostMediationSDK.FullscreenAdQueue) {
        record(.logEndQueue)
    }

}
