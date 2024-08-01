// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import UIKit

/// A `String` that identifies a partner.
public typealias PartnerID = String

/// The protocol to which all partner adapters conform to.
/// It defines how Chartboost Mediation SDK and its mediated networks communicate.
public protocol PartnerAdapter: AnyObject, PartnerErrorFactory, PartnerErrorMapping {
    /// The adapter configuration type that contains adapter and partner info.
    /// It may also be used to expose custom partner SDK options to the publisher.
    var configuration: PartnerAdapterConfiguration.Type { get }

    /// Does any setup needed before beginning to load ads.
    /// - parameter configuration: Configuration data for the adapter to set up.
    /// - parameter completion: Closure to be performed by the adapter when it's done setting up. It should include an error indicating
    /// the cause for failure or `nil` if the operation finished successfully.
    func setUp(
        with configuration: PartnerConfiguration,
        completion: @escaping (Result<PartnerDetails, Error>) -> Void
    )

    /// Fetches bidding tokens needed for the partner to participate in an auction.
    /// - parameter request: Information about the ad load request.
    /// - parameter completion: Closure to be performed with the fetched info.
    func fetchBidderInformation(
        request: PartnerAdPreBidRequest,
        completion: @escaping (Result<[String: String], Error>) -> Void
    )

    /// Indicates that the user consent has changed.
    /// - parameter consents: The new consents value, including both modified and unmodified consents.
    /// - parameter modifiedKeys: A set containing all the keys that changed.
    func setConsents(_ consents: [ConsentKey: ConsentValue], modifiedKeys: Set<ConsentKey>)

    /// Indicates that the user is underage signal has changed.
    /// - parameter isUserUnderage: `true` if the user is underage as determined by the publisher, `false` otherwise.
    func setIsUserUnderage(_ isUserUnderage: Bool)

    /// Creates a new banner ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// Chartboost Mediation SDK will always call this method from the main thread.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeBannerAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerBannerAd

    /// Creates a new ad object in charge of communicating with a single partner SDK ad instance.
    /// Chartboost Mediation SDK calls this method to create a new ad for each new load request. Ad instances are never reused.
    /// Chartboost Mediation SDK takes care of storing and disposing of ad instances so you don't need to.
    /// ``PartnerAd/invalidate()`` is called on ads before disposing of them in case partners need to perform any custom logic before the
    /// object gets destroyed.
    /// If, for some reason, a new ad cannot be provided, an error should be thrown.
    /// - parameter request: Information about the ad load request.
    /// - parameter delegate: The delegate that will receive ad life-cycle notifications.
    func makeFullscreenAd(request: PartnerAdLoadRequest, delegate: PartnerAdDelegate) throws -> PartnerFullscreenAd

    /// The designated initializer for the adapter.
    /// Chartboost Mediation SDK will use this constructor to create instances of conforming types.
    /// - parameter storage: An object that exposes storage managed by the Chartboost Mediation SDK to the adapter.
    /// It includes a list of created ``PartnerAd`` instances. You may ignore this parameter if you don't need it.
    init(storage: PartnerAdapterStorage)
}

/// Exposes storage managed by the Chartboost Mediation SDK to the adapter.
public protocol PartnerAdapterStorage: AnyObject {
    /// List of ``PartnerAd`` instances created by a ``PartnerAdapter`` that have not been disposed of yet.
    var ads: [PartnerAd] { get }
}

// Default implementations of ``PartnerErrorMapping`` methods.
extension PartnerAdapter {
    /// Default implementation of `mapSetUpError`.
    public func mapSetUpError(_ error: Error) -> ChartboostMediationError.Code? { nil }

    /// Default implementation of `mapPrebidError`.
    public func mapPrebidError(_ error: Error) -> ChartboostMediationError.Code? { nil }

    /// Default implementation of `mapLoadError`.
    public func mapLoadError(_ error: Error) -> ChartboostMediationError.Code? { nil }

    /// Default implementation of `mapShowError`.
    public func mapShowError(_ error: Error) -> ChartboostMediationError.Code? { nil }

    /// Default implementation of `mapInvalidateError`.
    public func mapInvalidateError(_ error: Error) -> ChartboostMediationError.Code? { nil }
}
