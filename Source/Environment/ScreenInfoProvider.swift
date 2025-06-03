// Copyright 2018-2025 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import ChartboostCoreSDK
import Foundation

protocol ScreenInfoProviding {
    var isDarkModeEnabled: Bool { get }
    var pixelRatio: Double { get }
    var screenBrightness: Double { get }
    var screenHeight: Double { get }
    var screenWidth: Double { get }
}

struct ScreenInfoProvider: ScreenInfoProviding {
    var isDarkModeEnabled: Bool {
        return mainScreen.traitCollection.userInterfaceStyle == .dark
    }

    var pixelRatio: Double {
        ChartboostCore.analyticsEnvironment.screenScale
    }

    var screenBrightness: Double {
        Double(mainScreen.brightness)
    }

    var screenHeight: Double {
        ChartboostCore.analyticsEnvironment.screenHeightPixels
    }

    var screenWidth: Double {
        ChartboostCore.analyticsEnvironment.screenWidthPixels
    }

    // MARK: - Private

    private var mainScreen: UIScreen {
        // `UIScreen.main` was deprecated in iOS 16. Apple doc:
        //   https://developer.apple.com/documentation/uikit/uiscreen/1617815-main
        // Since `UIScreen.main` has been working correctly at least up to iOS 16, the custom
        // implementation only targets iOS 17+, not iOS 13+.
        if #available(iOS 17.0, *) {
            return screenOfFirstConnectedWindowScene
        } else {
            return .main
        }
    }

    private var screenOfFirstConnectedWindowScene: UIScreen {
        var screen: UIScreen {
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let prioritizedActivationStates: [UIScene.ActivationState] = [
                .foregroundActive, // one and only one `foregroundActive` scene is expected
                .foregroundInactive,
                .background,
                .unattached,
            ]
            for activationState in prioritizedActivationStates {
                if let scene = windowScenes.first(where: { $0.activationState == activationState }) {
                    return scene.screen
                }
            }
            return .main
        }

        if Thread.isMainThread {
            return screen
        } else {
            return DispatchQueue.main.sync { screen }
        }
    }
}
