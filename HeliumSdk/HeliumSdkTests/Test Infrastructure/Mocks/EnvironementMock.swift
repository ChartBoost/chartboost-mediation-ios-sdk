// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation
@testable import ChartboostMediationSDK

final class EnvironmentMock: EnvironmentProviding {
    lazy var app: AppInfoProviding = AppInfoProviderMock()
    lazy var audio: AudioInfoProviding = AudioInfoProviderMock()
    lazy var device: DeviceInfoProviding = DeviceInfoProviderMock()
    lazy var screen: ScreenInfoProviding = ScreenInfoProviderMock()
    lazy var sdk: SDKInfoProviding = SDKInfoProviderMock()
    lazy var session: SessionInfoProviding = SessionInfoProviderMock()
    lazy var skAdNetwork: SKAdNetworkInfoProviding = SKAdNetworkInfoProviderMock()
    lazy var telephonyNetwork: TelephonyNetworkInfoProviding = TelephonyNetworkInfoProviderMock()
    lazy var testMode: TestModeInfoProviding = TestModeInfoProviderMock()
    lazy var userAgent: UserAgentProviding = UserAgentProviderMock()
    lazy var userIDProvider: UserIDProviding = UserIDProviderMock()
    lazy var userSettings: UserSettingsProviding = UserSettingsProviderMock()

    @Injected(\.appTrackingInfo)
    var appTracking

    @Injected(\.impressionCounter)
    var impressionCounter
}

extension EnvironmentMock {
    func randomizeAll() {
        (app as! AppInfoProviderMock).randomizeAll()
        (audio as! AudioInfoProviderMock).randomizeAll()
        (device as! DeviceInfoProviderMock).randomizeAll()
        (screen as! ScreenInfoProviderMock).randomizeAll()
        (sdk as! SDKInfoProviderMock).randomizeAll()
        (session as! SessionInfoProviderMock).randomizeAll()
        (skAdNetwork as! SKAdNetworkInfoProviderMock).randomizeAll()
        (telephonyNetwork as! TelephonyNetworkInfoProviderMock).randomizeAll()
        (testMode as! TestModeInfoProviderMock).randomizeAll()
        (userAgent as! UserAgentProviderMock).randomizeAll()
        (userIDProvider as! UserIDProviderMock).randomizeAll()
        (userSettings as! UserSettingsProviderMock).randomizeAll()
    }
}

/// This extension contains `Environment` dependencies, each with `randomizeAll()`.
extension EnvironmentMock {
    fileprivate final class AppInfoProviderMock: AppInfoProviding {
        var appID: String? = "some-app-identifier"
        var appSignature: String?
        var appVersion: String?
        var bundleID: String?
        var gameEngineName: String?
        var gameEngineVersion: String?

        func randomizeAll() {
            appID = Bool.random() ? String.random() : nil
            appSignature = Bool.random() ? String.random() : nil
            appVersion = Bool.random() ? String.random() : nil
            bundleID = Bool.random() ? String.random() : nil
            gameEngineName = Bool.random() ? String.random() : nil
            gameEngineVersion = Bool.random() ? String.random() : nil
        }
    }

    fileprivate final class AppTrackingInfoProviderMock: AppTrackingInfoProviding {
        var appTransparencyAuthStatus: UInt?
        var idfa: String?
        var idfv: String?
        var isLimitAdTrackingEnabled = false

        func randomizeAll() {
            appTransparencyAuthStatus = Bool.random() ? UInt.random(in: 0...3) : nil
            idfa = Bool.random() ? String.random() : nil
            idfv = Bool.random() ? String.random() : nil
            isLimitAdTrackingEnabled = Bool.random()
        }
    }

    fileprivate final class AudioInfoProviderMock: AudioInfoProviding {
        var audioInputTypes: [String] = []
        var audioOutputTypes: [String] = []
        var audioVolume: Double = 1

        func randomizeAll() {
            audioInputTypes = String.randomArray()
            audioOutputTypes = String.randomArray()
            audioVolume = Double(UInt.random(in: 1...100))
        }
    }

    fileprivate final class DeviceInfoProviderMock: DeviceInfoProviding {
        var batteryLevel: Double = 1
        var deviceMake = "Apple"
        var deviceModel = "iPhone"
        var deviceType: DeviceType = .iPhone
        var freeDiskSpace: UInt = 1000000
        var isBatteryCharging = false
        var osName = "iOS"
        var osVersion = "16.0"
        var totalDiskSpace: UInt = 5000000

        func randomizeAll() {
            batteryLevel = Double(UInt.random(in: 1...100))
            deviceMake = String.random()
            deviceModel = String.random()
            deviceType = Bool.random() ? .iPad : .iPhone
            freeDiskSpace = UInt.random(in: 1...100000000)
            isBatteryCharging = Bool.random()
            osName = String.random()
            osVersion = String.random()
            totalDiskSpace = UInt.random(in: 1...100000000)
        }
    }

    fileprivate final class ScreenInfoProviderMock: ScreenInfoProviding {
        var isDarkModeEnabled = false
        var pixelRatio: Double = 1
        var screenBrightness: Double = 1
        var screenHeight: Double = 600
        var screenWidth: Double = 800

        func randomizeAll() {
            isDarkModeEnabled = Bool.random()
            pixelRatio = Double(UInt.random(in: 1...1000))
            screenBrightness = Double(UInt.random(in: 1...1000))
            screenHeight = Double(UInt.random(in: 1...1000))
            screenWidth = Double(UInt.random(in: 1...1000))
        }
    }

    fileprivate final class SDKInfoProviderMock: SDKInfoProviding {
        var sdkName = "some SDK name"
        var sdkVersion = "some SDK version"

        func randomizeAll() {
            sdkName = String.random()
            sdkVersion = String.random()
        }
    }

    fileprivate final class SessionInfoProviderMock: SessionInfoProviding {
        var elapsedSessionDuration: TimeInterval = 0
        var sessionID = UUID()

        func randomizeAll() {
            elapsedSessionDuration = TimeInterval(UInt.random(in: 1...1000))
            sessionID = UUID()
        }
    }

    fileprivate final class SKAdNetworkInfoProviderMock: SKAdNetworkInfoProviding {
        var skAdNetworkIDs: [String] = []
        var skAdNetworkVersion = "1.0"

        func randomizeAll() {
            skAdNetworkIDs = String.randomArray()
            skAdNetworkVersion = String.random()
        }
    }

    fileprivate final class TelephonyNetworkInfoProviderMock: TelephonyNetworkInfoProviding {
        var carrierName = "some carrier name"
        var connectionType = NetworkConnectionType.unknown
        var mobileCountryCode: String?
        var mobileNetworkCode: String?
        var networkTypes: [String] = []

        func randomizeAll() {
            carrierName = String.random()
            connectionType = NetworkConnectionType(rawValue: Int.random(in: 0...NetworkConnectionType.cellular5G.rawValue))!
            mobileCountryCode = Bool.random() ? String.random() : nil
            mobileNetworkCode = Bool.random() ? String.random() : nil
            networkTypes = String.randomArray()
        }
    }

    final class TestModeInfoProviderMock: TestModeInfoProviding {
        var isTestModeEnabled = false
        var isRateLimitingEnabled = true
        var rtbAPIHostOverride: String? = nil
        var sdkAPIHostOverride: String? = nil

        func randomizeAll() {
            // No op.
            // Setting them to random values might break existing tests randomly.
            // These properties act as constants in Release builds because only
            // automation and Debug builds should change them, thus treating
            // them as constants in unit tests is sufficient.
        }
    }

    fileprivate final class UserIDProviderMock: UserIDProviding {
        var publisherUserID: String?
        var userID: String?

        func randomizeAll() {
            publisherUserID = Bool.random() ? String.random() : nil
            userID = Bool.random() ? String.random() : nil
        }
    }

    fileprivate final class UserSettingsProviderMock: UserSettingsProviding {
        var inputLanguages: [String] = ["en"]
        var isBoldTextEnabled = false
        var languageCode: String?
        var textSize: Double = 14

        func randomizeAll() {
            inputLanguages = String.randomArray()
            isBoldTextEnabled = Bool.random()
            languageCode = Bool.random() ? String.random() : nil
            textSize = Double(UInt.random(in: 1...100))
        }
    }

    fileprivate final class UserAgentProviderMock: UserAgentProviding {

        var userAgent: String? = "some user agent"

        func updateUserAgent() {

        }

        func randomizeAll() {
            userAgent = String.random()
        }
    }
}

extension String {
    static func random(length: Int = Int.random(in: 1...20), includeNumbers: Bool = true) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" + (includeNumbers ? "0123456789" : "")
        return String((0..<length).map{ _ in letters.randomElement()! })
    }

    static func randomArray(maxSize: Int = 5, length: Int = Int.random(in: 1...20), includeNumbers: Bool = true) -> [String] {
        let count = Int.random(in: 0...maxSize)
        guard count > 0 else { return [] }
        var arr = [String]()
        for _ in 0..<count {
            arr.append(String.random(length: length, includeNumbers: includeNumbers))
        }
        return arr
    }
}
