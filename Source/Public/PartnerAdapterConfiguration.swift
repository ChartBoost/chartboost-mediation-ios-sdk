// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import UIKit

/// A configuration type that contains adapter and partner info.
/// It may also be used to expose custom partner SDK options to the publisher.
@objc(CBMPartnerAdapterConfiguration)
public protocol PartnerAdapterConfiguration: NSObjectProtocol {
    /// The version of the partner SDK.
    @objc static var partnerSDKVersion: String { get }

    /// The version of the adapter.
    /// It should have either 5 or 6 digits separated by periods, where the first digit is Chartboost Mediation SDK's major version, the
    /// last digit is the adapter's build version, and intermediate digits are the partner SDK's version.
    /// Format: `<Chartboost Mediation major version>.<Partner major version>.<Partner minor version>.<Partner patch version>.
    /// <Partner build version>.<Adapter build version>` where `.<Partner build version>` is optional.
    @objc static var adapterVersion: String { get }

    /// The partner's unique identifier.
    @objc static var partnerID: PartnerID { get }

    /// The human-friendly partner name.
    @objc static var partnerDisplayName: String { get }
}

/// Provides logging capabilities to partner adapter configurations.
/// All functionality is provided by default implementations.
extension PartnerAdapterConfiguration {
    /// Logs an arbitrary message.
    /// - note: A default implementation is provided, so you don't need to implement this method in your adapter.
    public static func log(_ message: String, functionName: StaticString = #function) {
        PartnerLogger().log(message, from: self, functionName: functionName)
    }
}
