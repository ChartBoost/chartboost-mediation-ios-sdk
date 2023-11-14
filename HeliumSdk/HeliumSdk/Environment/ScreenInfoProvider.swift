// Copyright 2018-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

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
        if #available(iOS 12.0, *) {
            return mainScreen.traitCollection.userInterfaceStyle == .dark
        } else {
            return false
        }
    }

    var pixelRatio: Double {
        Double(mainScreen.scale)
    }

    var screenBrightness: Double {
        Double(mainScreen.brightness)
    }

    var screenHeight: Double {
        mainScreen.bounds.size.height * pixelRatio
    }

    var screenWidth: Double {
        mainScreen.bounds.size.width * pixelRatio
    }

    // MARK: - Private

    private var mainScreen: UIScreen {
        // `UIScreen.main` was deprecated in iOS 16. Apple doc:
        //   https://developer.apple.com/documentation/uikit/uiscreen/1617815-main
        // Since `UIScreen.main` has been working correctly at least up to iOS 16, the custom
        // implementation only targets iOS 17+, not iOS 13+.
        if #available(iOS 17.0, *) {
            if Thread.isMainThread {
                return UIApplication.screenOfFirstConnectedWindowScene
            } else {
                return DispatchQueue.main.sync { UIApplication.screenOfFirstConnectedWindowScene }
            }
        } else {
            return .main
        }
    }
}

extension UIApplication {

    /// This is a best-effort approach for obtaining the main screen of an app.
    /// Modern iOS supports multi-window scenarios on iPad, as well as newer technologies such as
    /// CarPlay which uses `CPTemplateApplicationScene` + `CPWindow` instead of `UIWindowScene` +
    /// `UIWindow`. Apple may remove the `UIScreen.main` API completely in the future, but we can
    /// use it as the fallback until then.
    /// Note: `UIApplication.connectedScenes` must be used from main thread only, so does this helper.
    @available(iOS 13.0, *)
    fileprivate static var screenOfFirstConnectedWindowScene: UIScreen {
        let windowScenes = shared.connectedScenes.compactMap({ $0 as? UIWindowScene })

        for activationState in [
            .foregroundActive, // one and only one `foregroundActive` scene is expected
            .foregroundInactive,
            .background,
            .unattached
        ] as [UIScene.ActivationState] {
            if let screen = windowScenes.first(where: { $0.activationState == activationState })?.screen {
                return screen
            }
        }

        return .main
    }
}
