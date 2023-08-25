// Copyright 2022-2023 Chartboost, Inc.
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
        // Use `sysctlbyname` to obtain the most specific device modle if possible.
        var size : Int = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var deviceModel = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &deviceModel, &size, nil, 0)
        return deviceModel.count > 0 ? String(cString: deviceModel) : UIDevice.current.model
    }

    var deviceType: DeviceType {
        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
    }

    var freeDiskSpace: UInt {
        guard
            let values = try? URL(fileURLWithPath:"/").resourceValues(forKeys: [.volumeAvailableCapacityKey]),
            let capacity = values.volumeAvailableCapacity
        else {
            return 0
        }
        return UInt(capacity)
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
        guard
            let values = try? URL(fileURLWithPath:"/").resourceValues(forKeys: [.volumeTotalCapacityKey]),
            let capacity = values.volumeTotalCapacity
        else {
            return 0
        }
        return UInt(capacity)
    }
}
