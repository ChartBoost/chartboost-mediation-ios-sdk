// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class ContainerPartnerAdapterFactoryTests: ChartboostMediationTestCase {

    lazy var factory = ContainerPartnerAdapterFactory()
    
    /// Validates that adapter objects are instantiated from their class names.
    func testAdaptersFrom2ClassNames() {
        let adapters = factory.adapters(fromClassNames: ["ChartboostMediationSDKTests.Adapter1", "ChartboostMediationSDKTests.Adapter2"])
        
        // Check returned adapters match expected count and type. Note classNames is a set and thus adapters order is undefined.
        XCTAssertEqual(adapters.count, 2)
        XCTAssert(adapters.contains(where: { $0.0 is Adapter1 }))
        XCTAssert(adapters.contains(where: { $0.0 is Adapter2 }))
    }
    
    /// Validates that an empty array is returned if an empty list of class names is passed.
    func testAdaptersFrom0ClassNames() {
        let adapters = factory.adapters(fromClassNames: [])
        
        XCTAssert(adapters.isEmpty)
    }
}

// Adapter classes to test

public final class Adapter1: PartnerAdapter {
    public var partnerSDKVersion = ""
    public var adapterVersion = ""
    public var partnerIdentifier = ""
    public var partnerDisplayName = ""
    
    public func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {}
    public func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {}
    public func setGDPR(applies: Bool?, status: GDPRConsentStatus) {}
    public func setCCPA(hasGivenConsent: Bool, privacyString: String) {}
    public func setCOPPA(isChildDirected: Bool) {}
    public func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd { throw NSError.test() }
    
    public init(storage: PartnerAdapterStorage) {}
}

public final class Adapter2: PartnerAdapter {
    public var partnerSDKVersion = ""
    public var adapterVersion = ""
    public var partnerIdentifier = ""
    public var partnerDisplayName = ""
    
    public func setUp(with configuration: PartnerConfiguration, completion: @escaping (Error?) -> Void) {}
    public func fetchBidderInformation(request: PreBidRequest, completion: @escaping ([String : String]?) -> Void) {}
    public func setGDPR(applies: Bool?, status: GDPRConsentStatus) {}
    public func setCCPA(hasGivenConsent: Bool, privacyString: String) {}
    public func setCOPPA(isChildDirected: Bool) {}
    public func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd { throw NSError.test() }
    
    public init(storage: PartnerAdapterStorage) {}
}
