// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class PartnerAdapterMock: Mock<PartnerAdapterMock.Method>, PartnerAdapter {
    
    enum Method {
        case setUp
        case fetchBidderInformation
        case setGDPR
        case setCCPA
        case setCOPPA
        case makeAd
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.makeAd: PartnerAdMock(adapter: self)]
    }
    
    var partnerSDKVersion = "partnerSDKVersion\(Int.random(in: 1...99999))"
    var adapterVersion = "adapterVersion\(Int.random(in: 1...99999))"
    var partnerIdentifier = "partnerIdentifier\(Int.random(in: 1...99999))"
    var partnerDisplayName = "partnerDisplayName\(Int.random(in: 1...99999))"
    
    override init() {}
    
    init(storage: PartnerAdapterStorage) { }
    
    func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {
        record(.setUp, parameters: [configuration, completion])
    }
    
    func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {
        record(.fetchBidderInformation, parameters: [request, completion])
    }
    
    func setGDPR(applies: Bool?, status: GDPRConsentStatus) {
        record(.setGDPR, parameters: [applies, status])
    }
    
    func setCCPA(hasGivenConsent: Bool, privacyString: String) {
        record(.setCCPA, parameters: [hasGivenConsent, privacyString])
    }
    
    func setCOPPA(isChildDirected: Bool) {
        record(.setCOPPA, parameters: [isChildDirected])
    }
    
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd {
        try throwingRecord(.makeAd, parameters: [request, delegate])
    }
}
