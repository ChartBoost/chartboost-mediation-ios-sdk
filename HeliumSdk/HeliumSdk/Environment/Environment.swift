// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol EnvironmentProviding {
    var app: AppInfoProviding { get }
    var appTracking: AppTrackingInfoProviding { get }
    var audio: AudioInfoProviding { get }
    var device: DeviceInfoProviding { get }
    var impressionCounter: ImpressionCounter { get }
    var screen: ScreenInfoProviding { get }
    var sdk: SDKInfoProviding { get }
    var session: SessionInfoProviding { get }
    var skAdNetwork: SKAdNetworkInfoProviding { get }
    var telephonyNetwork: TelephonyNetworkInfoProviding { get }
    var testMode: TestModeInfoProviding { get }
    var userAgent: UserAgentProviding { get }
    var userIDProvider: UserIDProviding { get }
    var userSettings: UserSettingsProviding { get }
}

struct Environment: EnvironmentProviding {

    let app: AppInfoProviding = AppInfoProvider()
    let audio: AudioInfoProviding = AudioInfoProvider()
    let device: DeviceInfoProviding = DeviceInfoProvider()
    let screen: ScreenInfoProviding = ScreenInfoProvider()
    let sdk: SDKInfoProviding = SDKInfoProvider()
    let session: SessionInfoProviding = SessionInfoProvider()
    let skAdNetwork: SKAdNetworkInfoProviding = SKAdNetworkInfoProvider()
    let telephonyNetwork: TelephonyNetworkInfoProviding = TelephonyNetworkInfoProvider()
    let testMode: TestModeInfoProviding = TestModeInfo()
    let userIDProvider: UserIDProviding = UserIDProvider()
    let userSettings: UserSettingsProviding = UserSettingsProvider()
    let userAgent: UserAgentProviding = UserAgentProvider()

    @Injected(\.appTrackingInfo)
    var appTracking

    @Injected(\.impressionCounter)
    var impressionCounter
}
