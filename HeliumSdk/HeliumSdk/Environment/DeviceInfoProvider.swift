// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

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

    let deviceMake = "Apple"

    var deviceModel: String {
        if #available(iOS 17.0, *) {
            @Injected(\.privacyConfiguration) var privacyConfig
            if privacyConfig.privacyBanList.contains(.sysctl) {
                return UIDevice.current.model
            }
        }

        // Use `sysctlbyname` to obtain the most specific device modle if possible.
        var size: Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var deviceModel = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &deviceModel, &size, nil, 0)
        return !deviceModel.isEmpty ? String(cString: deviceModel) : UIDevice.current.model
    }

    var deviceType: DeviceType {
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }

    var freeDiskSpace: UInt {
        if #available(iOS 17.0, *) {
            // Stop using `volumeAvailableCapacity(Key)` on iOS 17+ because it's a Required Reason API
            // and we don't have an approved reason to use it.
            return 0
        } else {
            guard
                let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
                let capacity = values.volumeAvailableCapacity
            else {
                return 0
            }
            return UInt(capacity)
        }
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
        UIDevice.current.systemVersion
    }

    var totalDiskSpace: UInt {
        if #available(iOS 17.0, *) {
            // Stop using `volumeTotalCapacity(Key)` on iOS 17+ because it's a Required Reason API
            // and we don't have an approved reason to use it.
            return 0
        } else {
            guard
                let values = try? URL(fileURLWithPath: "/").resourceValues(forKeys: [.volumeTotalCapacityKey]),
                let capacity = values.volumeTotalCapacity
            else {
                return 0
            }
            return UInt(capacity)
        }
    }
}
