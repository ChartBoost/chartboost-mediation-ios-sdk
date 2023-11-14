// Copyright 2018-2023 Chartboost, Inc.
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
        if #available(iOS 17.0, *) {
            // Stop using `UITextInputMode.activeInputModes` on iOS 17+ because it's a Required
            // Reason API and we don't have an approved reason to use it.
            return []
        } else {
            // HB-4356 revealed that multiple threads using the `inputLanguages` getter resulted in crashes.
            // To alleviate the crash, always access `activeInputModes` in the same serial queue.
            // On HB-6701 we found that the main queue must be used.
            func fetchValue() -> [String] {
                UITextInputMode.activeInputModes.compactMap(\.primaryLanguage)
            }
            if Thread.isMainThread {
                return fetchValue()
            } else {
                return DispatchQueue.main.sync { fetchValue() }
            }
        }
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
