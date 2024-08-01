// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class PartnerAdapterConfigurationMock1: NSObject, PartnerAdapterConfiguration {
    static var partnerSDKVersion = "partnerSDKVersion\(Int.random(in: 1...99999))"
    static var adapterVersion = "adapterVersion\(Int.random(in: 1...99999))"
    static var partnerID = "partnerIdentifier\(Int.random(in: 1...99999))"
    static var partnerDisplayName = "partnerDisplayName\(Int.random(in: 1...99999))"
}

class PartnerAdapterConfigurationMock2: NSObject, PartnerAdapterConfiguration {
    static var partnerSDKVersion = "partnerSDKVersion\(Int.random(in: 1...99999))"
    static var adapterVersion = "adapterVersion\(Int.random(in: 1...99999))"
    static var partnerID = "partnerIdentifier\(Int.random(in: 1...99999))"
    static var partnerDisplayName = "partnerDisplayName\(Int.random(in: 1...99999))"
}

class PartnerAdapterConfigurationMock3: NSObject, PartnerAdapterConfiguration {
    static var partnerSDKVersion = "partnerSDKVersion\(Int.random(in: 1...99999))"
    static var adapterVersion = "adapterVersion\(Int.random(in: 1...99999))"
    static var partnerID = "partnerIdentifier\(Int.random(in: 1...99999))"
    static var partnerDisplayName = "partnerDisplayName\(Int.random(in: 1...99999))"
}

final class PartnerAdapterMock<Configuration: PartnerAdapterConfiguration>: Mock<PartnerAdapterMock.Method>, PartnerAdapter {

    enum Method {
        case setUp
        case fetchBidderInformation
        case setConsents
        case setIsUserUnderage
        case makeBannerAd
        case makeFullscreenAd
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.makeBannerAd: PartnerAdMock(adapter: self),
         .makeFullscreenAd: PartnerAdMock(adapter: self)]
    }
    
    var configuration: PartnerAdapterConfiguration.Type = Configuration.self
    
    override init() {}
    
    init(storage: PartnerAdapterStorage) { }
    
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {
        record(.setUp, parameters: [configuration, completion])
    }
    
    func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {
        record(.fetchBidderInformation, parameters: [request, completion])
    }

    func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {
        record(.setConsents, parameters: [consents, modifiedKeys])
    }

    func setIsUserUnderage(_ isUserUnderage: Bool) {
        record(.setIsUserUnderage, parameters: [isUserUnderage])
    }
    
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd {
        try throwingRecord(.makeBannerAd, parameters: [request, delegate])
    }

    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd {
        try throwingRecord(.makeFullscreenAd, parameters: [request, delegate])
    }
}
