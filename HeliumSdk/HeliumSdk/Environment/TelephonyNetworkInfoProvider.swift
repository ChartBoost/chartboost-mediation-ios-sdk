// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import CoreTelephony

enum NetworkConnectionType: Int {
    case unknown = 0
    case wired = 1
    case wifi = 2
    case cellularUnknown = 3
    case cellular2G = 4
    case cellular3G = 5
    case cellular4G = 6
    case cellular5G = 7
}

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
        switch reachability.status {
        case .unknown, .notReachable:
            return .unknown

        case .reachableViaWiFi:
            return .wifi

        case .reachableViaWWAN:
            // https://developer.apple.com/documentation/coretelephony/cttelephonynetworkinfo/radio_access_technology_constants
            let currentRadioAccessTechnology = Self.networkInfo.currentRadioAccessTechnology

            switch currentRadioAccessTechnology {
            case CTRadioAccessTechnologyLTE:
                return .cellular4G

            case CTRadioAccessTechnologyCDMAEVDORev0,
                 CTRadioAccessTechnologyCDMAEVDORevA,
                 CTRadioAccessTechnologyCDMAEVDORevB,
                 CTRadioAccessTechnologyeHRPD,
                 CTRadioAccessTechnologyHSDPA,
                 CTRadioAccessTechnologyHSUPA,
                 CTRadioAccessTechnologyWCDMA:
                return .cellular3G

            case CTRadioAccessTechnologyCDMA1x,
                 CTRadioAccessTechnologyEdge,
                 CTRadioAccessTechnologyGPRS:
                return .cellular2G

            default:
                if #available(iOS 14.1, *) {
                    if currentRadioAccessTechnology == CTRadioAccessTechnologyNR ||
                       currentRadioAccessTechnology == CTRadioAccessTechnologyNRNSA {
                        return .cellular5G
                    }
                }
                return .unknown
            }
        }
    }

    var mobileCountryCode: String? {
        currentCarrier?.mobileCountryCode
    }

    var mobileNetworkCode: String? {
        currentCarrier?.mobileNetworkCode
    }

    var networkTypes: [String] {
        if #available(iOS 12.0, *) {
            return Self.networkInfo.serviceCurrentRadioAccessTechnology.map { Array($0.values) } ?? []
        } else {
            return Self.networkInfo.currentRadioAccessTechnology.map { [$0] } ?? []
        }
    }

    // MARK: - Private

    private var currentCarrier: CTCarrier? {
        if #available(iOS 12.0, *) {
            if let carriers = Self.networkInfo.serviceSubscriberCellularProviders {
                if #available(iOS 13.0, *) {
                    if let serviceID = Self.networkInfo.dataServiceIdentifier, let carrier = carriers[serviceID] {
                        return carrier
                    }
                }

                // If there's exactly one entry, then we know which carrier is in use
                if carriers.count == 1, let carrier = carriers.values.first {
                    return carrier
                }
            }
        }

        // If nothing else has worked, try `subscriberCellularProvider` deprecated in iOS 16.
        return Self.networkInfo.subscriberCellularProvider
    }
}
