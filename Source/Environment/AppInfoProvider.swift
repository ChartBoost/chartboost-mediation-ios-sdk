// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

protocol AppInfoProviding: AnyObject {
    var chartboostAppID: String? { get set }
    var appVersion: String? { get }
    var bundleID: String? { get }
    var gameEngineName: String? { get }
    var gameEngineVersion: String? { get }
}

final class AppInfoProvider: AppInfoProviding {
    @Injected(\.bundleInfo) private var bundleInfo
    @Injected(\.infoPlist) private var infoPlist

    var chartboostAppID: String?

    var appVersion: String? {
        ChartboostCore.analyticsEnvironment.appVersion
    }

    var bundleID: String? {
        ChartboostCore.analyticsEnvironment.bundleID
    }

    var gameEngineName: String? {
        ChartboostCore.analyticsEnvironment.frameworkName
    }

    var gameEngineVersion: String? {
        ChartboostCore.analyticsEnvironment.frameworkVersion
    }
}
