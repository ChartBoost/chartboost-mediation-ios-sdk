// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

class PartnerControllerMock: Mock<PartnerControllerMock.Method>, PartnerController {
    
    enum Method {
        case setUpAdapters
        case routeLoad
        case routeShow
        case routeInvalidate
        case routeFetchBidderInformation
        case didChangeGDPR
        case didChangeCCPA
        case didChangeCOPPA
        case cancelLoad
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.routeLoad: { self.record(.cancelLoad) } as CancelAction]
    }
    
    var initializedAdapterInfo: [PartnerIdentifier : PartnerAdapterInfo] = [:]
    
    func setUpAdapters(
        configurations: [PartnerIdentifier : PartnerConfiguration],
        adapterClasses: Set<String>,
        skipping partnerIdentifiersToSkip: Set<PartnerIdentifier>,
        completion: @escaping ([MetricsEvent]) -> Void
    ) {
        record(.setUpAdapters, parameters: [configurations, adapterClasses, partnerIdentifiersToSkip, completion])
    }
    
    func routeLoad(request: PartnerAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (Result<PartnerAd, ChartboostMediationError>) -> Void) -> CancelAction {
        record(.routeLoad, parameters: [request, viewController, delegate, completion])
    }
    
    func routeShow(_ ad: PartnerAd, viewController: UIViewController, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.routeShow, parameters: [ad, viewController, completion])
    }
    
    func routeInvalidate(_ ad: PartnerAd, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.routeInvalidate, parameters: [ad, completion])
    }
    
    func routeFetchBidderInformation(request: PreBidRequest, completion: @escaping ([PartnerIdentifier : [String : String]]) -> Void) {
        record(.routeFetchBidderInformation, parameters: [request, completion])
    }
    
    func didChangeGDPR() {
        record(.didChangeGDPR)
    }
    
    func didChangeCCPA() {
        record(.didChangeCCPA)
    }
    
    func didChangeCOPPA() {
        record(.didChangeCOPPA)
    }
}
