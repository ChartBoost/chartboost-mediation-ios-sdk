// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import CoreTelephony

protocol TelephonyNetworkInfoProviding {
    var carrierName: String { get }
    var connectionType: NetworkConnectionType { get }
    var mobileCountryCode: String? { get }
    var mobileNetworkCode: String? { get }
    var networkTypes: [String] { get }
}

struct TelephonyNetworkInfoProvider: TelephonyNetworkInfoProviding {
    private enum Constant {
        static let unknownCarrierName = "Unknown"
    }

    /// This is `static` to make sure it's only instantiated once, since this class may cause crashes
    /// if deallocated due to a known Apple bug.
    private static let networkInfo = CTTelephonyNetworkInfo()

    @Injected(\.reachability) private var reachability

    var carrierName: String {
        currentCarrier?.carrierName ?? Constant.unknownCarrierName
    }

    var connectionType: NetworkConnectionType {
        ChartboostCore.analyticsEnvironment.networkConnectionType
    }

    var mobileCountryCode: String? {
        currentCarrier?.mobileCountryCode
    }

    var mobileNetworkCode: String? {
        currentCarrier?.mobileNetworkCode
    }

    var networkTypes: [String] {
        return Self.networkInfo.serviceCurrentRadioAccessTechnology.map { Array($0.values) } ?? []
    }

    // MARK: - Private

    private var currentCarrier: CTCarrier? {
        if let carriers = Self.networkInfo.serviceSubscriberCellularProviders {
            if let serviceID = Self.networkInfo.dataServiceIdentifier, let carrier = carriers[serviceID] {
                return carrier
            }

            // If there's exactly one entry, then we know which carrier is in use
            if carriers.count == 1, let carrier = carriers.values.first {
                return carrier
            } else {
                // If there are multiple SIMs, return the first one with a carrier name.
                // (Approach suggested by https://stackoverflow.com/a/71119915)
                return carriers.first(where: { $0.value.carrierName != nil })?.value
            }
        } else {
            return nil
        }
    }
}
