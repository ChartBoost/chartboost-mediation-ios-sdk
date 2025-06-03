// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import XCTest
@testable import ChartboostMediationSDK

class ContainerPartnerAdapterFactoryTests: ChartboostMediationTestCase {

    lazy var factory = ContainerPartnerAdapterFactory()
    
    /// Validates that adapter objects are instantiated from their class names.
    func testAdaptersFrom2ClassNames() {
        let adapters = factory.adapters(fromClassNames: ["\(currentModuleClassNamePrefix).Adapter1", "\(currentModuleClassNamePrefix).Adapter2"])

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

    private var currentModuleClassNamePrefix: String {
        NSStringFromClass(Self.self).components(separatedBy: ".").first ?? ""
    }
}

// Adapter classes to test

public final class Adapter1: PartnerAdapter {
    public var configuration: PartnerAdapterConfiguration.Type = AdapterConfiguration.self
    public func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {}
    public func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {}
    public func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {}
    public func setIsUserUnderage(_ isUserUnderage: Bool) {}
    public func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd { throw NSError.test() }
    public func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd { throw NSError.test() }

    public init(storage: PartnerAdapterStorage) {}
}

public final class AdapterConfiguration: NSObject, PartnerAdapterConfiguration {
    public static var partnerSDKVersion = ""
    public static var adapterVersion = ""
    public static var partnerID = ""
    public static var partnerDisplayName = ""
}

public final class Adapter2: PartnerAdapter {
    public var configuration: PartnerAdapterConfiguration.Type = AdapterConfiguration.self
    public func setUp(with configuration: PartnerConfiguration, completion: @escaping (Result<PartnerDetails, Error>) -> Void) {}
    public func fetchBidderInformation(request: PartnerAdPreBidRequest, completion: @escaping (Result<[String : String], Error>) -> Void) {}
    public func setConsents(_ consents: [ConsentKey : ConsentValue], modifiedKeys: Set<ConsentKey>) {}
    public func setIsUserUnderage(_ isUserUnderage: Bool) {}
    public func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd { throw NSError.test() }
    public func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd { throw NSError.test() }
    public func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd { throw NSError.test() }

    public init(storage: PartnerAdapterStorage) {}
}
