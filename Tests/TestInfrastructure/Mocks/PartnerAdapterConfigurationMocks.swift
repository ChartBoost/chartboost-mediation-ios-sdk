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
