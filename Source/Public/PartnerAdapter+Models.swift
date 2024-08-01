// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

extension PartnerAdapter {
    /// A key in a partner consents dictionary.
    /// Defined as a typealias so adapters do not need to explicitly import the ChartboostCoreSDK in order
    /// to access these constants.
    public typealias ConsentKey = ChartboostCoreSDK.ConsentKey

    /// A namespace for consent keys to be used by partner adapters.
    /// Defined as a typealias so adapters do not need to explicitly import the ChartboostCoreSDK in order
    /// to access these constants.
    public typealias ConsentKeys = ChartboostCoreSDK.ConsentKeys

    /// A value in a partner consents dictionary.
    /// Defined as a typealias so adapters do not need to explicitly import the ChartboostCoreSDK in order
    /// to access these constants.
    public typealias ConsentValue = ChartboostCoreSDK.ConsentValue

    /// A namespace for consent values to be used by partner adapters.
    /// Defined as a typealias so adapters do not need to explicitly import the ChartboostCoreSDK in order
    /// to access these constants.
    public typealias ConsentValues = ChartboostCoreSDK.ConsentValues
}

/// Extra information related to a partner event as a dictionary.
/// Pass an empty dictionary when there are no details to pass back to the Chartboost Mediation SDK.
public typealias PartnerDetails = [String: Any]

/// A partner ad load request.
public struct PartnerAdLoadRequest: Equatable {
    /// Partner's identifier.
    public let partnerID: PartnerID
    /// Chartboost Mediation's placement identifier.
    public let mediationPlacement: String
    /// Partner's placement identifier.
    public let partnerPlacement: String
    /// Ad format.
    public var format: PartnerAdFormat { internalAdFormat.partnerAdFormat }
    /// Ad size. `nil` for full-screen ads.
    public let bannerSize: BannerSize?
    /// String containing the bid's adm. `nil` for non-programmatic line items.
    public let adm: String?
    /// Key-value pairs to be associated with the placement.
    public let keywords: [String: String]
    /// Extra partner-specific information.
    public let partnerSettings: [String: Any]
    /// A unique identifier for the load request.
    public let identifier: String
    /// The identifier for the auction associated with this request.
    let auctionID: String
    /// Preferred internal name of the public `identifier`.
    var loadID: String { identifier }
    /// The internal ad format associated.
    let internalAdFormat: AdFormat

    // MARK: Equatable
    public static func == (lhs: PartnerAdLoadRequest, rhs: PartnerAdLoadRequest) -> Bool {
        @Injected(\.jsonSerializer) var serializer
        guard let lhsData = try? serializer.serialize(lhs.partnerSettings), let lhsJsonString = String(data: lhsData, encoding: .utf8),
              let rhsData = try? serializer.serialize(rhs.partnerSettings), let rhsJsonString = String(data: rhsData, encoding: .utf8),
              lhsJsonString == rhsJsonString else {
            return false
        }
        guard lhs.partnerID == rhs.partnerID
                && lhs.mediationPlacement == rhs.mediationPlacement
                && lhs.partnerPlacement == rhs.partnerPlacement
                && lhs.format == rhs.format
                && lhs.bannerSize?.size == rhs.bannerSize?.size
                && lhs.bannerSize?.type == rhs.bannerSize?.type
                && lhs.adm == rhs.adm
                && lhs.identifier == rhs.identifier
                && lhs.auctionID == rhs.auctionID
                && lhs.internalAdFormat == rhs.internalAdFormat
        else {
            return false
        }
        return true
    }
}

/// A prebidding info request.
public struct PartnerAdPreBidRequest {
    /// Chartboost Mediation's placement identifier.
    public let mediationPlacement: String
    /// Ad format.
    public let format: PartnerAdFormat
    /// Ad size. `nil` for full-screen ads.
    public let bannerSize: BannerSize?
    /// Extra partner-specific information.
    public let partnerSettings: [String: Any]
    /// Key-value pairs to be associated with the placement.
    public let keywords: [String: String]
    /// A unique identifier for the load request, which is the same as the associated `AdLoadRequest.loadID`.
    let loadID: String
    /// The internal ad format associated.
    let internalAdFormat: AdFormat
}

/// Ad format.
public typealias PartnerAdFormat = String

/// A namespace for Mediation's `PartnerAdFormat` constants.
/// - note: Formats are defined as string constants instead of enum cases to prevent adapters from doing
/// exhaustive switches over an ad format value. Doing so can break the adapter compatibility with new
/// Mediation SDK minor versions if a new format is introduced.
public enum PartnerAdFormats {
    // We use same values as in the internal AdFormat model to make conversions easier.

    /// Banner ad format.
    public static let banner = AdFormat.banner.partnerAdFormat

    /// Interstitial ad format.
    public static let interstitial = AdFormat.interstitial.partnerAdFormat

    /// Rewarded ad format.
    public static let rewarded = AdFormat.rewarded.partnerAdFormat

    /// Rewarded interstitial ad format.
    public static let rewardedInterstitial = AdFormat.rewardedInterstitial.partnerAdFormat

    /// Indicates if the format is a banner.
    static func isBanner(_ format: PartnerAdFormat) -> Bool {
        format == Self.banner
    }

    /// Indicates if the format is fullscreen.
    static func isFullscreen(_ format: PartnerAdFormat) -> Bool {
        !isBanner(format)
    }
}

/// The size of a partner loaded banner ad.
public struct PartnerBannerSize: Equatable {
    /// The underlying `CGSize`.
    public let size: CGSize

    /// The banner type.
    public let type: BannerType

    /// Public constructor.
    public init(size: CGSize, type: BannerType) {
        self.size = size
        self.type = type
    }
}

/// Information used by partner adapters to set up.
public struct PartnerConfiguration {
    /// A dictionary containing any partner-specific information required on setup.
    public let credentials: [String: Any]

    /// Initial consent info at the moment of initialization.
    /// Changes will be reported via calls to ``PartnerAdapter/setConsents(_:modifiedKeys:)``.
    public let consents: [PartnerAdapter.ConsentKey: PartnerAdapter.ConsentValue]

    /// Indicates if the user is underage as determined by the publisher.
    /// Changes will be reported via calls to ``PartnerAdapter/setIsUserUnderage(_:)``.
    public let isUserUnderage: Bool
}
