// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import UIKit

/// The protocol to which all partner adapters conform to.
/// It defines how Chartboost Mediation SDK and its mediated networks communicate.
public protocol PartnerAdapter: AnyObject {
    
    /// The version of the partner SDK.
    var partnerSDKVersion: String { get }
    
    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.<Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    var adapterVersion: String { get }
    
    /// The partner's unique identifier.
    var partnerIdentifier: String { get }
    
    /// The human-friendly partner name.
    var partnerDisplayName: String { get }
    
    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating the cause for failure or `nil` if the operation finished successfully.
    func setUp(
        with configuration: PartnerConfiguration,
        completion: @escaping (Error?) -> Void
    )
    
    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(
        request: PreBidRequest,
        completion: @escaping ([String: String]?) -> Void
    )
    
    /// Indicates if GDPR applies or not and the user's GDPR consent status.
    /// - parameter applies: `true` if GDPR applies, `false` if not, `nil` if the publisher has not provided this information.
    /// - parameter status: One of the ``GDPRConsentStatus`` values depending on the user's preference.
    func setGDPR(applies: Bool?, status: GDPRConsentStatus)
    
    /// Indicates the CCPA status both as a boolean and as an IAB US privacy string.
    /// - parameter hasGivenConsent: A boolean indicating if the user has given consent.
    /// - parameter privacyString: An IAB-compliant string indicating the CCPA status.
    func setCCPA(hasGivenConsent: Bool, privacyString: String)
    
    /// Indicates if the user is subject to COPPA or not.
    /// - parameter isChildDirected: `true` if the user is subject to COPPA, `false` otherwise.
    func setCOPPA(isChildDirected: Bool)
    
    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread for banner ads.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerAd
    
    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created ``PartnerAd`` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage)
    
    // MARK: Optional
    
    /// Maps a partner setup error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a setup completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapSetUpError(_ error: Error) -> ChartboostMediationError.Code?
    
    /// Maps a partner prebid error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a fetch bidder info completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapPrebidError(_ error: Error) -> ChartboostMediationError.Code?
    
    /// Maps a partner load error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a load completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapLoadError(_ error: Error) -> ChartboostMediationError.Code?
    
    /// Maps a partner show error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a show completion is called with a partner error.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapShowError(_ error: Error) -> ChartboostMediationError.Code?
    
    /// Maps a partner invalidate error to a Chartboost Mediation error code.
    /// Chartboost Mediation SDK calls this method when a partner error is thrown on invalidate.
    ///
    /// A default implementation is provided that returns `nil`.
    /// Only implement if the partner SDK provides its own list of error codes that can be mapped to Chartboost Mediation's.
    /// If some case cannot be mapped return `nil` to let Chartboost Mediation choose a default error code.
    func mapInvalidateError(_ error: Error) -> ChartboostMediationError.Code?
}

/// Exposes storage managed by the Chartboost Mediation SDK to the adapter.
public protocol PartnerAdapterStorage: AnyObject {
    /// List of ``PartnerAd`` instances created by a ``PartnerAdapter`` that have not been disposed of yet.
    var ads: [PartnerAd] { get }
}

/// `PartnerAdapter` extension that provides a default implementation for all error mapping methods.
public extension PartnerAdapter {
    
    func mapSetUpError(_ error: Error) -> ChartboostMediationError.Code? { nil }
    
    func mapPrebidError(_ error: Error) -> ChartboostMediationError.Code? { nil }
    
    func mapLoadError(_ error: Error) -> ChartboostMediationError.Code? { nil }
    
    func mapShowError(_ error: Error) -> ChartboostMediationError.Code? { nil }
    
    func mapInvalidateError(_ error: Error) -> ChartboostMediationError.Code? { nil }
}
