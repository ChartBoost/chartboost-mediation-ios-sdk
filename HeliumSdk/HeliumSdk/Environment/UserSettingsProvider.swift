// Copyright 2018-2024 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

protocol UserSettingsProviding {
    var inputLanguages: [String] { get }
    var isBoldTextEnabled: Bool { get }
    var languageCode: String? { get }
    var textSize: Double { get }
}

final class UserSettingsProvider: UserSettingsProviding {
    var inputLanguages: [String] {
        // Stop using `UITextInputMode.activeInputModes` on iOS 17+ because it's a Required
        // Reason API and we don't have an approved reason to use it.
        return []
    }

    var isBoldTextEnabled: Bool {
        UIAccessibility.isBoldTextEnabled
    }

    var languageCode: String? {
        if #available(iOS 17.0, *) {
            @Injected(\.privacyConfiguration) var privacyConfig
            if privacyConfig.privacyBanList.contains(.languageAndLocale) {
                return nil
            }
        }

        if #available(iOS 16.0, *) {
            if let languageCode = Locale.current.language.languageCode?.identifier {
                return languageCode
            }
        } else {
            if let languageCode = Locale.current.languageCode {
                return languageCode
            }
        }

        return Locale.preferredLanguages.first
    }

    var textSize: Double {
        Double(UIFont.preferredFont(forTextStyle: .body).pointSize)
    }
}
