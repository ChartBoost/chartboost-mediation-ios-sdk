// Copyright 2018-2024 Chartboost, Inc.
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
        case cancelLoad
    }
    
    override var defaultReturnValues: [Method : Any?] {
        [.routeLoad: { self.record(.cancelLoad) } as CancelAction]
    }
    
    var initializedAdapterInfo: [PartnerID: InternalPartnerAdapterInfo] = [:]

    func setUpAdapters(
        credentials: [PartnerID: [String: Any]],
        adapterClasses: Set<String>,
        skipping partnerIDsToSkip: Set<PartnerID>,
        completion: @escaping ([MetricsEvent]) -> Void
    ) {
        record(.setUpAdapters, parameters: [credentials, adapterClasses, partnerIDsToSkip, completion])
    }
    
    func routeLoad(request: PartnerAdLoadRequest, viewController: UIViewController?, delegate: PartnerAdDelegate, completion: @escaping (Result<PartnerAd, ChartboostMediationError>) -> Void) -> CancelAction {
        record(.routeLoad, parameters: [request, viewController, delegate, completion])
    }
    
    func routeShow(_ ad: PartnerFullscreenAd, viewController: UIViewController, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.routeShow, parameters: [ad, viewController, completion])
    }
    
    func routeInvalidate(_ ad: PartnerAd, completion: @escaping (ChartboostMediationError?) -> Void) {
        record(.routeInvalidate, parameters: [ad, completion])
    }

    func routeFetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping ([PartnerID : [String : String]]) -> Void) {
        record(.routeFetchBidderInformation, parameters: [request, completion])
    }
}
