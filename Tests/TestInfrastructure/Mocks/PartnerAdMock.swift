// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class PartnerAdMock: Mock<PartnerAdMock.Method>, PartnerBannerAd, PartnerFullscreenAd {

    enum Method {
        case load
        case invalidate
        case show
    }
    
    init(
        adapter: PartnerAdapter = PartnerAdapterMock<PartnerAdapterConfigurationMock1>(),
        request: PartnerAdLoadRequest = .test(),
        bannerView: UIView? = nil,
        bannerSize: PartnerBannerSize? = nil
    ) {
        self.adapter = adapter
        self.request = request
        self.view = bannerView
        self.size = bannerSize
    }
    
    var adapter: PartnerAdapter

    var details: PartnerDetails = [:]

    var request: PartnerAdLoadRequest
    
    var delegate: PartnerAdDelegate?
    
    var view: UIView?

    var size: PartnerBannerSize?

    func load(with viewController: UIViewController?, completion: @escaping (Error?) -> Void) {
        record(.load, parameters: [viewController, completion])
    }
    
    func show(with viewController: UIViewController, completion: @escaping (Error?) -> Void) {
        record(.show, parameters: [viewController, completion])
    }
    
    func invalidate() throws {
        try throwingRecord(.invalidate)
    }
}
