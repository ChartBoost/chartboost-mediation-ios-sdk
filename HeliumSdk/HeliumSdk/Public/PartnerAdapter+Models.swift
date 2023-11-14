// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A partner ad load request.
public struct PartnerAdLoadRequest: Equatable {
    /// Partner's identifier.
    public let partnerIdentifier: String
    /// Chartboost Mediation's placement identifier.
    public let chartboostPlacement: String
    /// Partner's placement identifier.
    public let partnerPlacement: String
    /// Ad format.
    public let format: AdFormat
    /// Ad size. `nil` for full-screen ads.
    public let size: CGSize?
    /// String containing the bid's adm. `nil` for non-programmatic line items.
    public let adm: String?
    /// Extra partner-specific information.
    public let partnerSettings: [String: Any]
    /// A unique identifier for the load request.
    public let identifier: String
    /// The identifier for the auction associated with this request.
    internal let auctionIdentifier: String
    /// Preferred internal name of the public `identifier`.
    var loadID: String { identifier }

    // MARK: Equatable
    public static func == (lhs: PartnerAdLoadRequest, rhs: PartnerAdLoadRequest) -> Bool {
        @Injected(\.jsonSerializer) var serializer
        guard let lhsData = try? serializer.serialize(lhs.partnerSettings), let lhsJsonString = String(data: lhsData, encoding: .utf8),
              let rhsData = try? serializer.serialize(rhs.partnerSettings), let rhsJsonString = String(data: rhsData, encoding: .utf8),
              lhsJsonString == rhsJsonString else {
            return false
        }
        guard lhs.partnerIdentifier == rhs.partnerIdentifier
                && lhs.chartboostPlacement == rhs.chartboostPlacement
                && lhs.partnerPlacement == rhs.partnerPlacement
                && lhs.format == rhs.format
                && lhs.size == rhs.size
                && lhs.adm == rhs.adm
                && lhs.identifier == rhs.identifier
                && lhs.auctionIdentifier == rhs.auctionIdentifier else {
            return false
        }
        return true
    }
}

/// A prebidding info request.
public struct PreBidRequest: Equatable {
    /// Chartboost Mediation's placement identifier.
    public let chartboostPlacement: String
    /// Ad format.
    public let format: AdFormat
    /// A unique identifier for the load request, which is the same as the associated `AdLoadRequest.loadID`.
    let loadID: String
}

/// Extra information related to a partner event as a dictionary of strings.
/// Pass an empty dictionary when there are no details to pass back to the Chartboost Mediation SDK.
public typealias PartnerEventDetails = [String: String]

/// Ad format.
public enum AdFormat: String, CaseIterable {
    case adaptiveBanner = "adaptive_banner"                 // snake-case for compatibility with backend
    case banner
    case interstitial
    case rewarded
    case rewardedInterstitial = "rewarded_interstitial"     // snake-case for compatibility with backend
}

extension AdFormat {
    /// Returns `true` if this is `adaptiveBanner` or `banner`, or false if it's a fullscreen ad.
    var isBanner: Bool {
        self == .adaptiveBanner || self == .banner
    }
}

/// Information used by partner adapters to set up.
public struct PartnerConfiguration {
    /// A dictionary containing any partner-specific information required on setup.
    public let credentials: [String: Any]
}

/// GDPR consent status.
public enum GDPRConsentStatus: Equatable {
    case unknown
    case denied
    case granted
}

/// IAB's standard 320x50 ad size as defined in IAB's [Fixed Size Ad Specification](https://www.iab.com/wp-content/uploads/2019/04/IABNewAdPortfolio_LW_FixedSizeSpec.pdf).
public let IABStandardAdSize = CGSize(width: 320, height: 50)

/// IAB's medium 300x250 ad size as defined in IAB's [Fixed Size Ad Specification](https://www.iab.com/wp-content/uploads/2019/04/IABNewAdPortfolio_LW_FixedSizeSpec.pdf).
public let IABMediumAdSize = CGSize(width: 300, height: 250)

/// IAB's leaderboard 728x90 ad size as defined in IAB's [Fixed Size Ad Specification](https://www.iab.com/wp-content/uploads/2019/04/IABNewAdPortfolio_LW_FixedSizeSpec.pdf).
public let IABLeaderboardAdSize = CGSize(width: 728, height: 90)
