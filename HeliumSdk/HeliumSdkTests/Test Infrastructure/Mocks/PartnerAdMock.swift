// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class PartnerAdMock: Mock<PartnerAdMock.Method>, PartnerAd {
    
    enum Method {
        case load
        case invalidate
        case show
    }
    
    init(adapter: PartnerAdapter = PartnerAdapterMock(), request: PartnerAdLoadRequest = .test(), inlineView: UIView? = nil) {
        self.adapter = adapter
        self.request = request
        self.inlineView = inlineView
    }
    
    var adapter: PartnerAdapter
    
    var request: PartnerAdLoadRequest
    
    var delegate: PartnerAdDelegate?
    
    var inlineView: UIView?
    
    func load(with viewController: UIViewController?, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        record(.load, parameters: [viewController, completion])
    }
    
    func show(with viewController: UIViewController, completion: @escaping (Result<PartnerEventDetails, Error>) -> Void) {
        record(.show, parameters: [viewController, completion])
    }
    
    func invalidate() throws {
        try throwingRecord(.invalidate)
    }
}
