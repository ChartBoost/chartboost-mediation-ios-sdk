// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

enum DeviceType {
    case iPhone
    case iPad
}

protocol DeviceInfoProviding {
    var batteryLevel: Double { get }
    var deviceMake: String { get }
    var deviceModel: String { get }
    var deviceType: DeviceType { get }
    var freeDiskSpace: UInt { get }
    var isBatteryCharging: Bool { get }
    var osName: String { get }
    var osVersion: String { get }
    var totalDiskSpace: UInt { get }
}

struct DeviceInfoProvider: DeviceInfoProviding {
    var batteryLevel: Double {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Double(UIDevice.current.batteryLevel)
    }

    var deviceMake: String {
        ChartboostCore.analyticsEnvironment.deviceMake
    }

    var deviceModel: String {
        if #available(iOS 17.0, *) {
            @Injected(\.privacyConfiguration) var privacyConfig
            if privacyConfig.privacyBanList.contains(.sysctl) {
                return UIDevice.current.model
            }
        }
        return ChartboostCore.analyticsEnvironment.deviceModel
    }

    var deviceType: DeviceType {
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }

    var freeDiskSpace: UInt {
        // Stop using `volumeAvailableCapacity(Key)` on iOS 17+ because it's a Required Reason API
        // and we don't have an approved reason to use it.
        return 0
    }

    var isBatteryCharging: Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true

        switch UIDevice.current.batteryState {
        case .charging, .full: // full state only happens if plugged
            return true

        case .unplugged, .unknown:
            return false

        @unknown default:
            assertionFailure("Unknown battery state: \(UIDevice.current.batteryState)")
            return false
        }
    }

    /// Hardcoded as "iOS" for all Apple OSs ("iPadOS", "watchOS", and "macOS") because the bidders
    /// only recognize "iOS" in their business logic.
    let osName = "iOS"

    var osVersion: String {
        ChartboostCore.analyticsEnvironment.osVersion
    }

    var totalDiskSpace: UInt {
        // Stop using `volumeTotalCapacity(Key)` on iOS 17+ because it's a Required Reason API
        // and we don't have an approved reason to use it.
        return 0
    }
}
