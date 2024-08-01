// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// An event with metrics and other relevant info intended to be logged to our servers and on console.
struct MetricsEvent: Encodable {
    enum NetworkType: String {
        case bidding
        case mediation
    }

    // WARNING: The name of each case of this enum must match the strings passed by the backend on app config "metricsEvents".
    // They should not be renamed!
    enum EventType: String, CaseIterable {
        case initialization
        case prebid
        case load
        case show
        case click
        case expiration
        case mediationImpression = "helium_impression"
        case partnerImpression = "partner_impression"
        case reward
        case winner
        case bannerSize = "banner_size"
        case startQueue
        case endQueue
    }

    /// Start time the event started.
    let start: Date

    /// Start time the event ended.
    let end: Date

    /// The total duration of the event.
    var duration: TimeInterval {
        end.timeIntervalSince1970 - start.timeIntervalSince1970
    }

    /// Error for the operation the event refers to. If nil it is assumed that the operation was successful.
    let error: ChartboostMediationError?

    /// The identifier of the partner associated to this event.
    let partnerID: PartnerID

    /// Version number of the partner SDK
    let partnerSDKVersion: String?

    /// Version number of the PartnerAdapter this event came from
    let partnerAdapterVersion: String?

    /// The partner placement associated to this event.
    let partnerPlacement: String?

    /// The network type of the partner associated to this event.
    let networkType: NetworkType?

    /// The line item identifier associated to this event.
    let lineItemIdentifier: String?

    init(
        start: Date,
        end: Date = Date(),
        error: ChartboostMediationError? = nil,
        partnerID: PartnerID,
        partnerSDKVersion: String? = nil,
        partnerAdapterVersion: String? = nil,
        partnerPlacement: String? = nil,
        networkType: NetworkType? = nil,
        lineItemIdentifier: String? = nil
    ) {
        self.start = start
        self.end = end
        self.error = error
        self.partnerID = partnerID
        self.partnerSDKVersion = partnerSDKVersion
        self.partnerAdapterVersion = partnerAdapterVersion
        self.partnerPlacement = partnerPlacement
        self.networkType = networkType
        self.lineItemIdentifier = lineItemIdentifier
    }

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case start
        case end
        case duration
        case error = "helium_error"
        case errorCode = "helium_error_code"
        case errorMessage = "helium_error_message"
        case isSuccess = "is_success"
        case partnerID = "partner"
        case partnerSDKVersion = "partner_sdk_version"
        case partnerAdapterVersion = "partner_adapter_version"
        case partnerPlacement = "partner_placement"
        case networkType = "network_type"
        case lineItemIdentifer = "line_item_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(partnerID, forKey: .partnerID)
        try container.encode(partnerSDKVersion, forKey: .partnerSDKVersion)
        try container.encode(partnerAdapterVersion, forKey: .partnerAdapterVersion)
        try container.encode(start.unixTimestamp, forKey: .start)
        try container.encode(end.unixTimestamp, forKey: .end)
        try container.encode(Int(duration * 1000), forKey: .duration)
        if let error {
            try container.encode(error.chartboostMediationCode.name, forKey: .error)
            try container.encode(error.chartboostMediationCode.string, forKey: .errorCode)
            try container.encode(error.chartboostMediationCode.message, forKey: .errorMessage)
            try container.encode(false, forKey: .isSuccess)
        } else {
            try container.encode(true, forKey: .isSuccess)
        }
        if let networkType {
            try container.encode(networkType.rawValue, forKey: .networkType)
        }
        if let lineItemIdentifer = lineItemIdentifier {
            try container.encode(lineItemIdentifer, forKey: .lineItemIdentifer)
        }
        if let partnerPlacement {
            try container.encode(partnerPlacement, forKey: .partnerPlacement)
        }
    }
}

extension Date {
    var unixTimestamp: Int {
        Int(timeIntervalSince1970 * 1000)
    }
}
